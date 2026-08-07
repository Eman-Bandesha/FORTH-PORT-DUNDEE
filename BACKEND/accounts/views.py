import logging

from django.conf import settings
from django.contrib.auth import authenticate
from django.contrib.auth.models import User, update_last_login
from django.db.models import Q
from django.utils import timezone
from rest_framework import mixins, permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenRefreshView

from .email_service import send_password_changed_email, send_verification_code_email
from .models import AccountStatus, PasswordResetOTP, UserProfile
from .permissions import IsAdminRole
from .security import (
    check_and_bump_rate_limit,
    check_resend_cooldown,
    client_ip,
    create_otp_for_user,
    create_reset_token,
    get_valid_reset_token,
    resolve_active_user,
    revoke_user_tokens,
    verify_secret,
)
from .serializers import (
    AdminUserCreateSerializer,
    AdminUserUpdateSerializer,
    ChangePasswordSerializer,
    ForgotPasswordSerializer,
    ProfileUpdateSerializer,
    ResetPasswordSerializer,
    UserSerializer,
    VerifyOTPSerializer,
)

logger = logging.getLogger(__name__)

GENERIC_FORGOT_MESSAGE = (
    "If an active account exists, a verification code has been sent."
)
INACTIVE_MESSAGE = (
    "This account is inactive. Please contact your administrator."
)


def _tokens_for_user(user: User) -> dict:
    refresh = RefreshToken.for_user(user)
    return {
        "refresh": str(refresh),
        "access": str(refresh.access_token),
    }


def _account_blocked_response():
    return Response({"detail": INACTIVE_MESSAGE}, status=status.HTTP_403_FORBIDDEN)


def _ensure_profile(user: User) -> UserProfile:
    profile, _ = UserProfile.objects.get_or_create(user=user)
    return profile


class LoginView(APIView):
    permission_classes = (permissions.AllowAny,)

    def post(self, request):
        username = request.data.get("username") or request.data.get("email")
        password = request.data.get("password")
        if not username or not password:
            return Response(
                {"detail": "username (or email) and password are required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Resolve user first to give a clear inactive message (without revealing
        # whether password was correct when inactive).
        candidate = resolve_active_user(str(username))
        if candidate is not None:
            profile = _ensure_profile(candidate)
            if (
                not candidate.is_active
                or profile.account_status != AccountStatus.ACTIVE
            ):
                return _account_blocked_response()

        user = authenticate(request, username=username, password=password)
        if user is None and "@" in str(username):
            try:
                match = User.objects.get(email__iexact=username)
                user = authenticate(
                    request, username=match.username, password=password
                )
            except User.DoesNotExist:
                user = None

        if user is None:
            return Response(
                {"detail": "Invalid credentials."},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        profile = _ensure_profile(user)
        if not user.is_active or profile.account_status != AccountStatus.ACTIVE:
            return _account_blocked_response()

        update_last_login(None, user)
        data = {
            "user": UserSerializer(user).data,
            "tokens": _tokens_for_user(user),
            "must_change_password": profile.must_change_password,
        }
        return Response(data)


class RegisterView(APIView):
    """Public signup is disabled — staff accounts are created by admins only."""

    permission_classes = (permissions.AllowAny,)

    def post(self, request):
        return Response(
            {
                "detail": (
                    "Public registration is disabled. "
                    "Ask your administrator to create your staff account."
                )
            },
            status=status.HTTP_403_FORBIDDEN,
        )


class UserViewSet(
    mixins.ListModelMixin,
    mixins.RetrieveModelMixin,
    mixins.CreateModelMixin,
    mixins.UpdateModelMixin,
    mixins.DestroyModelMixin,
    viewsets.GenericViewSet,
):
    """Admin-only user management for the web console."""

    permission_classes = (permissions.IsAuthenticated, IsAdminRole)
    queryset = User.objects.select_related("profile").order_by("first_name", "username")

    def get_serializer_class(self):
        if self.action == "create":
            return AdminUserCreateSerializer
        if self.action in ("update", "partial_update"):
            return AdminUserUpdateSerializer
        return UserSerializer

    def get_queryset(self):
        qs = super().get_queryset()
        search = self.request.query_params.get("search")
        if search:
            qs = qs.filter(
                Q(username__icontains=search)
                | Q(email__icontains=search)
                | Q(first_name__icontains=search)
                | Q(last_name__icontains=search)
            )
        role = self.request.query_params.get("role")
        if role:
            qs = qs.filter(profile__role__iexact=role)
        status_param = (self.request.query_params.get("status") or "").lower()
        if status_param in ("active", "inactive", "suspended", "deactivated"):
            if status_param == "active":
                qs = qs.filter(profile__account_status=AccountStatus.ACTIVE)
            elif status_param == "suspended":
                qs = qs.filter(profile__account_status=AccountStatus.SUSPENDED)
            elif status_param in ("inactive", "deactivated"):
                qs = qs.filter(
                    Q(profile__account_status=AccountStatus.DEACTIVATED)
                    | Q(is_active=False)
                )
        return qs

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        payload = UserSerializer(user).data
        temp = getattr(user, "_generated_temporary_password", None)
        if temp and settings.DEBUG:
            payload["temporary_password"] = temp
        return Response(payload, status=status.HTTP_201_CREATED)

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop("partial", False)
        instance = self.get_object()
        serializer = self.get_serializer(
            instance, data=request.data, partial=partial
        )
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        payload = UserSerializer(user).data
        temp = getattr(user, "_generated_temporary_password", None)
        if temp and settings.DEBUG:
            payload["temporary_password"] = temp
        return Response(payload)

    def destroy(self, request, *args, **kwargs):
        """Soft-deactivate: keep user row and related stock/audit history."""
        instance = self.get_object()
        if instance.pk == request.user.pk:
            return Response(
                {"detail": "You cannot deactivate your own account."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        profile = _ensure_profile(instance)
        profile.account_status = AccountStatus.DEACTIVATED
        profile.save(update_fields=["account_status"])
        instance.is_active = False
        instance.save(update_fields=["is_active"])
        revoke_user_tokens(instance)
        return Response(
            {
                "detail": "Account deactivated. Stock and audit records were kept.",
                "user": UserSerializer(instance).data,
            }
        )

    @action(detail=True, methods=["post"], url_path="suspend")
    def suspend(self, request, pk=None):
        user = self.get_object()
        if user.pk == request.user.pk:
            return Response(
                {"detail": "You cannot suspend your own account."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        profile = _ensure_profile(user)
        profile.account_status = AccountStatus.SUSPENDED
        profile.save(update_fields=["account_status"])
        user.is_active = False
        user.save(update_fields=["is_active"])
        revoke_user_tokens(user)
        return Response(UserSerializer(user).data)

    @action(detail=True, methods=["post"], url_path="reactivate")
    def reactivate(self, request, pk=None):
        user = self.get_object()
        profile = _ensure_profile(user)
        profile.account_status = AccountStatus.ACTIVE
        profile.save(update_fields=["account_status"])
        user.is_active = True
        user.save(update_fields=["is_active"])
        return Response(UserSerializer(user).data)

    @action(detail=True, methods=["post"], url_path="reset-password")
    def reset_password(self, request, pk=None):
        user = self.get_object()
        serializer = AdminUserUpdateSerializer(
            user,
            data={
                "reset_temporary_password": True,
                "send_reset_email": request.data.get("send_reset_email", True),
            },
            partial=True,
        )
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        payload = UserSerializer(user).data
        temp = getattr(user, "_generated_temporary_password", None)
        if temp and settings.DEBUG:
            payload["temporary_password"] = temp
        return Response(payload)


class MeView(APIView):
    def get(self, request):
        return Response(UserSerializer(request.user).data)

    def patch(self, request):
        serializer = ProfileUpdateSerializer(
            request.user, data=request.data, partial=True
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(UserSerializer(request.user).data)


class LogoutView(APIView):
    def post(self, request):
        refresh = request.data.get("refresh")
        if refresh:
            try:
                token = RefreshToken(refresh)
                token.blacklist()
            except Exception:
                logger.info("Logout: refresh token could not be blacklisted")
        return Response({"detail": "Logged out."})


class RotatingTokenRefreshView(TokenRefreshView):
    """Refresh with rotation + blacklist (configured in SIMPLE_JWT)."""


class ForgotPasswordView(APIView):
    permission_classes = (permissions.AllowAny,)

    def post(self, request):
        serializer = ForgotPasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        identifier = serializer.validated_data["identifier"]
        ip = client_ip(request) or "unknown"

        # Rate limit by IP and by identifier
        ip_ok, ip_retry = check_and_bump_rate_limit(
            f"forgot:ip:{ip}",
            max_count=getattr(settings, "PASSWORD_RESET_IP_RATE_LIMIT", 10),
            window_seconds=getattr(settings, "PASSWORD_RESET_RATE_WINDOW_SECONDS", 3600),
        )
        id_ok, id_retry = check_and_bump_rate_limit(
            f"forgot:id:{identifier.lower()}",
            max_count=getattr(settings, "PASSWORD_RESET_USER_RATE_LIMIT", 5),
            window_seconds=getattr(settings, "PASSWORD_RESET_RATE_WINDOW_SECONDS", 3600),
        )
        if not ip_ok or not id_ok:
            return Response(
                {
                    "detail": "Too many requests. Please try again later.",
                    "retry_after": max(ip_retry, id_retry),
                },
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )

        user = resolve_active_user(identifier)
        response_payload = {"detail": GENERIC_FORGOT_MESSAGE}

        if user is None:
            return Response(response_payload)

        profile = _ensure_profile(user)
        if not user.is_active or profile.account_status != AccountStatus.ACTIVE:
            # Still generic to avoid account enumeration, but log internally.
            logger.info("Forgot password blocked for inactive user id=%s", user.pk)
            return Response(response_payload)

        if not user.email:
            logger.warning("User %s has no email for password reset", user.pk)
            return Response(response_payload)

        cooldown_ok, wait = check_resend_cooldown(user)
        if not cooldown_ok:
            return Response(
                {
                    "detail": "Please wait before requesting another code.",
                    "retry_after": wait,
                },
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )

        otp_record, code = create_otp_for_user(user, ip=ip)
        send_verification_code_email(user, code)
        logger.info("Password reset OTP created id=%s user=%s", otp_record.pk, user.pk)

        if settings.DEBUG and getattr(settings, "EXPOSE_OTP_IN_DEBUG", False):
            response_payload["debug_otp"] = code

        return Response(response_payload)


class VerifyOTPView(APIView):
    permission_classes = (permissions.AllowAny,)

    def post(self, request):
        serializer = VerifyOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        identifier = serializer.validated_data["identifier"]
        otp_code = serializer.validated_data["otp"].strip()

        user = resolve_active_user(identifier)
        if user is None:
            return Response(
                {"detail": "Invalid or expired verification code.", "valid": False},
                status=status.HTTP_400_BAD_REQUEST,
            )

        profile = _ensure_profile(user)
        if not user.is_active or profile.account_status != AccountStatus.ACTIVE:
            return _account_blocked_response()

        record = (
            PasswordResetOTP.objects.filter(user=user, used=False)
            .order_by("-created_at")
            .first()
        )
        if record is None or record.is_expired:
            return Response(
                {"detail": "Invalid or expired verification code.", "valid": False},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if record.is_locked:
            return Response(
                {
                    "detail": "Too many incorrect attempts. Request a new code.",
                    "valid": False,
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        if not verify_secret(otp_code, record.code_hash):
            record.attempt_count += 1
            record.save(update_fields=["attempt_count"])
            remaining = max(0, record.max_attempts - record.attempt_count)
            return Response(
                {
                    "detail": "Invalid or expired verification code.",
                    "valid": False,
                    "attempts_remaining": remaining,
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Success: mark OTP used (prevent reuse) and issue short-lived reset token
        record.used = True
        record.used_at = timezone.now()
        record.save(update_fields=["used", "used_at"])

        token_record, raw_token = create_reset_token(user, otp=record)
        return Response(
            {
                "valid": True,
                "reset_token": raw_token,
                "expires_at": token_record.expires_at.isoformat(),
            }
        )


class ResetPasswordView(APIView):
    permission_classes = (permissions.AllowAny,)

    def post(self, request):
        serializer = ResetPasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        raw_token = serializer.validated_data["reset_token"]
        new_password = serializer.validated_data["new_password"]

        token = get_valid_reset_token(raw_token)
        if token is None:
            return Response(
                {"detail": "Invalid or expired reset token."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user = token.user
        profile = _ensure_profile(user)
        if not user.is_active or profile.account_status != AccountStatus.ACTIVE:
            return _account_blocked_response()

        user.set_password(new_password)
        user.save()
        profile.must_change_password = False
        profile.password_changed_at = timezone.now()
        profile.save(update_fields=["must_change_password", "password_changed_at"])

        token.used = True
        token.used_at = timezone.now()
        token.save(update_fields=["used", "used_at"])
        if token.otp_id:
            PasswordResetOTP.objects.filter(pk=token.otp_id, used=False).update(
                used=True, used_at=timezone.now()
            )

        revoke_user_tokens(user)
        send_password_changed_email(user)
        logger.info("Password reset completed for user id=%s", user.pk)

        return Response(
            {
                "detail": "Password updated. Please sign in with your new password.",
            }
        )


class ChangePasswordView(APIView):
    """Authenticated password change (also clears must_change_password)."""

    def post(self, request):
        serializer = ChangePasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        profile = _ensure_profile(request.user)

        current = serializer.validated_data.get("current_password") or ""
        # When forced change after temp password, still require current password
        # unless explicitly skipped by must_change with correct current.
        if not request.user.check_password(current):
            return Response(
                {"detail": "Current password is incorrect."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        request.user.set_password(serializer.validated_data["new_password"])
        request.user.save()
        profile.must_change_password = False
        profile.password_changed_at = timezone.now()
        profile.save(update_fields=["must_change_password", "password_changed_at"])
        revoke_user_tokens(request.user)
        send_password_changed_email(request.user)

        # Issue fresh tokens after password change
        return Response(
            {
                "detail": "Password updated.",
                "tokens": _tokens_for_user(request.user),
                "user": UserSerializer(request.user).data,
            }
        )
