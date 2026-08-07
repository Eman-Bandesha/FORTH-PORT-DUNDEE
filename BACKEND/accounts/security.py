"""Security helpers: OTP hashing, JWT revocation, rate limits, temp passwords."""
from __future__ import annotations

import hashlib
import logging
import secrets
import string
from datetime import timedelta

from django.conf import settings
from django.contrib.auth.hashers import check_password, make_password
from django.contrib.auth.models import User
from django.utils import timezone

from .models import AuthRateLimit, PasswordResetOTP, PasswordResetToken

logger = logging.getLogger(__name__)


def hash_secret(value: str) -> str:
    return make_password(value)


def verify_secret(plain: str, hashed: str) -> bool:
    return check_password(plain, hashed)


def sha256_hex(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def generate_otp_code(length: int = 6) -> str:
    return "".join(secrets.choice(string.digits) for _ in range(length))


def generate_temporary_password(length: int = 12) -> str:
    alphabet = string.ascii_letters + string.digits + "!@#$%"
    # Ensure complexity for Django validators
    parts = [
        secrets.choice(string.ascii_uppercase),
        secrets.choice(string.ascii_lowercase),
        secrets.choice(string.digits),
        secrets.choice("!@#$%"),
    ]
    parts += [secrets.choice(alphabet) for _ in range(max(0, length - 4))]
    secrets.SystemRandom().shuffle(parts)
    return "".join(parts)


def generate_reset_token() -> str:
    return secrets.token_urlsafe(32)


def client_ip(request) -> str | None:
    forwarded = request.META.get("HTTP_X_FORWARDED_FOR")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.META.get("REMOTE_ADDR")


def revoke_user_tokens(user: User) -> int:
    """Blacklist all outstanding refresh tokens for a user."""
    try:
        from rest_framework_simplejwt.token_blacklist.models import (
            BlacklistedToken,
            OutstandingToken,
        )
    except Exception:
        logger.warning("JWT blacklist app not available; skip token revocation")
        return 0

    count = 0
    for outstanding in OutstandingToken.objects.filter(user=user):
        _, created = BlacklistedToken.objects.get_or_create(token=outstanding)
        if created:
            count += 1
    return count


def otp_expiry() -> timezone.datetime:
    minutes = getattr(settings, "PASSWORD_RESET_OTP_MINUTES", 10)
    return timezone.now() + timedelta(minutes=minutes)


def reset_token_expiry() -> timezone.datetime:
    minutes = getattr(settings, "PASSWORD_RESET_TOKEN_MINUTES", 15)
    return timezone.now() + timedelta(minutes=minutes)


def invalidate_previous_otps(user: User) -> None:
    PasswordResetOTP.objects.filter(user=user, used=False).update(
        used=True, used_at=timezone.now()
    )


def create_otp_for_user(user: User, ip: str | None = None) -> tuple[PasswordResetOTP, str]:
    invalidate_previous_otps(user)
    code = generate_otp_code(6)
    record = PasswordResetOTP.objects.create(
        user=user,
        email=user.email.lower(),
        code_hash=hash_secret(code),
        expires_at=otp_expiry(),
        request_ip=ip,
        max_attempts=getattr(settings, "PASSWORD_RESET_MAX_ATTEMPTS", 5),
    )
    return record, code


def create_reset_token(user: User, otp: PasswordResetOTP | None = None) -> tuple[PasswordResetToken, str]:
    raw = generate_reset_token()
    record = PasswordResetToken.objects.create(
        user=user,
        otp=otp,
        token_hash=sha256_hex(raw),
        expires_at=reset_token_expiry(),
    )
    return record, raw


def get_valid_reset_token(raw: str) -> PasswordResetToken | None:
    try:
        record = PasswordResetToken.objects.select_related("user", "otp").get(
            token_hash=sha256_hex(raw)
        )
    except PasswordResetToken.DoesNotExist:
        return None
    if not record.is_valid:
        return None
    if record.user and not record.user.is_active:
        return None
    return record


def check_and_bump_rate_limit(
    key: str,
    *,
    max_count: int,
    window_seconds: int,
) -> tuple[bool, int]:
    """
    Returns (allowed, retry_after_seconds).
    If not allowed, retry_after is remaining window seconds.
    """
    now = timezone.now()
    obj, _ = AuthRateLimit.objects.get_or_create(key=key)
    window = timedelta(seconds=window_seconds)
    if obj.window_started + window < now:
        obj.count = 0
        obj.window_started = now
    if obj.count >= max_count:
        remaining = int((obj.window_started + window - now).total_seconds())
        return False, max(remaining, 1)
    obj.count += 1
    obj.last_request_at = now
    obj.save(update_fields=["count", "window_started", "last_request_at"])
    return True, 0


def check_resend_cooldown(user: User) -> tuple[bool, int]:
    """60-second cooldown between OTP sends for the same user."""
    cooldown = getattr(settings, "PASSWORD_RESET_RESEND_COOLDOWN_SECONDS", 60)
    latest = (
        PasswordResetOTP.objects.filter(user=user).order_by("-created_at").first()
    )
    if not latest:
        return True, 0
    elapsed = (timezone.now() - latest.created_at).total_seconds()
    if elapsed < cooldown:
        return False, int(cooldown - elapsed) + 1
    return True, 0


def resolve_active_user(identifier: str) -> User | None:
    """Find user by username or email. Returns None if missing."""
    ident = (identifier or "").strip()
    if not ident:
        return None
    user = User.objects.filter(username__iexact=ident).select_related("profile").first()
    if user is None and "@" in ident:
        user = (
            User.objects.filter(email__iexact=ident).select_related("profile").first()
        )
    return user
