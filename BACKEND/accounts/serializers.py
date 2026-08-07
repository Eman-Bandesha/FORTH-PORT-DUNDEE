from django.contrib.auth.models import User
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from django.utils import timezone
from rest_framework import serializers

from .email_service import send_account_setup_email, send_admin_password_reset_email
from .models import AccountStatus, UserProfile
from .security import generate_temporary_password, revoke_user_tokens


class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserProfile
        fields = (
            "role",
            "department",
            "phone",
            "account_status",
            "must_change_password",
            "password_changed_at",
        )


class UserSerializer(serializers.ModelSerializer):
    profile = UserProfileSerializer(read_only=True)
    name = serializers.SerializerMethodField()
    role = serializers.SerializerMethodField()
    status = serializers.SerializerMethodField()
    account_status = serializers.SerializerMethodField()
    must_change_password = serializers.SerializerMethodField()
    last_login_display = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = (
            "id",
            "username",
            "email",
            "first_name",
            "last_name",
            "name",
            "role",
            "status",
            "account_status",
            "must_change_password",
            "is_active",
            "last_login",
            "last_login_display",
            "profile",
        )
        read_only_fields = fields

    def get_name(self, obj: User) -> str:
        full = obj.get_full_name().strip()
        return full or obj.username

    def get_role(self, obj: User) -> str:
        profile = getattr(obj, "profile", None)
        return profile.role if profile else "Staff"

    def get_status(self, obj: User) -> str:
        profile = getattr(obj, "profile", None)
        if profile:
            return {
                AccountStatus.ACTIVE: "Active",
                AccountStatus.SUSPENDED: "Suspended",
                AccountStatus.DEACTIVATED: "Deactivated",
            }.get(profile.account_status, "Inactive")
        return "Active" if obj.is_active else "Inactive"

    def get_account_status(self, obj: User) -> str:
        profile = getattr(obj, "profile", None)
        return profile.account_status if profile else (
            AccountStatus.ACTIVE if obj.is_active else AccountStatus.DEACTIVATED
        )

    def get_must_change_password(self, obj: User) -> bool:
        profile = getattr(obj, "profile", None)
        return bool(profile and profile.must_change_password)

    def get_last_login_display(self, obj: User) -> str | None:
        if not obj.last_login:
            return None
        local = obj.last_login
        try:
            from django.utils import timezone as tz

            local = tz.localtime(obj.last_login)
        except Exception:
            pass
        return local.strftime("%d %b %Y, %I:%M %p").replace(" 0", " ")


class AdminUserCreateSerializer(serializers.Serializer):
    first_name = serializers.CharField(required=False, allow_blank=True, default="")
    last_name = serializers.CharField(required=False, allow_blank=True, default="")
    email = serializers.EmailField()
    username = serializers.CharField(required=False, allow_blank=True)
    role = serializers.ChoiceField(
        choices=("Administrator", "Staff"), required=False, default="Staff"
    )
    department = serializers.CharField(required=False, allow_blank=True, default="")
    phone = serializers.CharField(required=False, allow_blank=True, default="")
    account_status = serializers.ChoiceField(
        choices=AccountStatus.choices, required=False, default=AccountStatus.ACTIVE
    )
    # Optional: admin may supply a password; otherwise a temp password is generated.
    password = serializers.CharField(
        write_only=True, required=False, allow_blank=True, min_length=8
    )
    generate_temporary_password = serializers.BooleanField(required=False, default=True)
    send_setup_email = serializers.BooleanField(required=False, default=True)

    def validate_email(self, value: str) -> str:
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return value.lower()

    def create(self, validated_data):
        email = validated_data["email"]
        username = (validated_data.get("username") or "").strip() or email.split("@")[0]
        base = username
        n = 1
        while User.objects.filter(username__iexact=username).exists():
            username = f"{base}{n}"
            n += 1

        generate_temp = validated_data.get("generate_temporary_password", True)
        raw_password = (validated_data.get("password") or "").strip()
        if generate_temp or not raw_password:
            raw_password = generate_temporary_password()
            must_change = True
        else:
            must_change = True  # always force change for admin-created accounts

        account_status = validated_data.get("account_status") or AccountStatus.ACTIVE
        user = User(
            username=username,
            email=email,
            first_name=validated_data.get("first_name", ""),
            last_name=validated_data.get("last_name", ""),
            is_active=account_status == AccountStatus.ACTIVE,
        )
        user.set_password(raw_password)
        user.save()
        UserProfile.objects.create(
            user=user,
            role=validated_data.get("role") or "Staff",
            department=validated_data.get("department") or "",
            phone=validated_data.get("phone") or "",
            account_status=account_status,
            must_change_password=must_change,
        )
        user._generated_temporary_password = raw_password  # type: ignore[attr-defined]
        email_sent = False
        if validated_data.get("send_setup_email", True) and user.email:
            email_sent = bool(
                send_account_setup_email(user, raw_password, username)
            )
        user._setup_email_sent = email_sent  # type: ignore[attr-defined]
        return user


class AdminUserUpdateSerializer(serializers.Serializer):
    first_name = serializers.CharField(required=False, allow_blank=True)
    last_name = serializers.CharField(required=False, allow_blank=True)
    email = serializers.EmailField(required=False)
    username = serializers.CharField(required=False)
    role = serializers.ChoiceField(
        choices=("Administrator", "Staff"), required=False
    )
    department = serializers.CharField(required=False, allow_blank=True)
    phone = serializers.CharField(required=False, allow_blank=True)
    is_active = serializers.BooleanField(required=False)
    account_status = serializers.ChoiceField(
        choices=AccountStatus.choices, required=False
    )
    password = serializers.CharField(
        write_only=True, required=False, allow_blank=True, min_length=8
    )
    reset_temporary_password = serializers.BooleanField(required=False, default=False)
    send_reset_email = serializers.BooleanField(required=False, default=True)

    def update(self, instance: User, validated_data):
        for field in ("first_name", "last_name", "email", "username"):
            if field in validated_data:
                setattr(instance, field, validated_data[field])

        profile, _ = UserProfile.objects.get_or_create(user=instance)
        for field in ("role", "department", "phone"):
            if field in validated_data:
                setattr(profile, field, validated_data[field])

        if "account_status" in validated_data:
            profile.account_status = validated_data["account_status"]
            instance.is_active = profile.account_status == AccountStatus.ACTIVE
        elif "is_active" in validated_data:
            instance.is_active = validated_data["is_active"]
            profile.account_status = (
                AccountStatus.ACTIVE
                if instance.is_active
                else AccountStatus.DEACTIVATED
            )

        temp_password = None
        if validated_data.get("reset_temporary_password"):
            temp_password = generate_temporary_password()
            instance.set_password(temp_password)
            profile.must_change_password = True
            profile.password_changed_at = timezone.now()
            revoke_user_tokens(instance)
        else:
            password = validated_data.get("password")
            if password:
                instance.set_password(password)
                profile.must_change_password = True
                profile.password_changed_at = timezone.now()
                revoke_user_tokens(instance)

        instance.save()
        profile.save()

        if temp_password and validated_data.get("send_reset_email", True) and instance.email:
            email_sent = bool(
                send_admin_password_reset_email(instance, temp_password)
            )
            instance._generated_temporary_password = temp_password  # type: ignore[attr-defined]
            instance._setup_email_sent = email_sent  # type: ignore[attr-defined]
        elif temp_password:
            instance._generated_temporary_password = temp_password  # type: ignore[attr-defined]
            instance._setup_email_sent = False  # type: ignore[attr-defined]

        if not instance.is_active:
            revoke_user_tokens(instance)

        return instance


class ProfileUpdateSerializer(serializers.ModelSerializer):
    department = serializers.CharField(required=False)
    phone = serializers.CharField(required=False)

    class Meta:
        model = User
        fields = ("first_name", "last_name", "email", "department", "phone")

    def update(self, instance, validated_data):
        profile_fields = {}
        for key in ("department", "phone"):
            if key in validated_data:
                profile_fields[key] = validated_data.pop(key)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        if profile_fields:
            profile, _ = UserProfile.objects.get_or_create(user=instance)
            for attr, value in profile_fields.items():
                setattr(profile, attr, value)
            profile.save()
        return instance


class ForgotPasswordSerializer(serializers.Serializer):
    # Accept username OR email in a single field (also support legacy "email").
    username = serializers.CharField(required=False, allow_blank=True)
    email = serializers.CharField(required=False, allow_blank=True)

    def validate(self, attrs):
        identifier = (attrs.get("username") or attrs.get("email") or "").strip()
        if not identifier:
            raise serializers.ValidationError(
                {"username": "Enter your username or registered email."}
            )
        attrs["identifier"] = identifier
        return attrs


class VerifyOTPSerializer(serializers.Serializer):
    username = serializers.CharField(required=False, allow_blank=True)
    email = serializers.CharField(required=False, allow_blank=True)
    otp = serializers.CharField(min_length=6, max_length=6)

    def validate(self, attrs):
        identifier = (attrs.get("username") or attrs.get("email") or "").strip()
        if not identifier:
            raise serializers.ValidationError(
                {"username": "Enter your username or registered email."}
            )
        attrs["identifier"] = identifier
        return attrs


class ResetPasswordSerializer(serializers.Serializer):
    reset_token = serializers.CharField()
    new_password = serializers.CharField(write_only=True)
    confirm_password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        if attrs["new_password"] != attrs["confirm_password"]:
            raise serializers.ValidationError(
                {"confirm_password": "Passwords do not match."}
            )
        try:
            validate_password(attrs["new_password"])
        except DjangoValidationError as exc:
            raise serializers.ValidationError({"new_password": list(exc.messages)})
        return attrs


class ChangePasswordSerializer(serializers.Serializer):
    current_password = serializers.CharField(
        write_only=True, required=False, allow_blank=True
    )
    new_password = serializers.CharField(write_only=True)
    confirm_password = serializers.CharField(write_only=True, required=False)

    def validate(self, attrs):
        confirm = attrs.get("confirm_password")
        if confirm is not None and attrs["new_password"] != confirm:
            raise serializers.ValidationError(
                {"confirm_password": "Passwords do not match."}
            )
        try:
            validate_password(attrs["new_password"])
        except DjangoValidationError as exc:
            raise serializers.ValidationError({"new_password": list(exc.messages)})
        return attrs
