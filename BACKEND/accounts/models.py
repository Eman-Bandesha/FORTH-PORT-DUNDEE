from django.conf import settings
from django.contrib.auth.models import User
from django.db import models
from django.utils import timezone


class AccountStatus(models.TextChoices):
    ACTIVE = "active", "Active"
    SUSPENDED = "suspended", "Suspended"
    DEACTIVATED = "deactivated", "Deactivated"


class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="profile")
    role = models.CharField(max_length=120, default="Staff")
    department = models.CharField(max_length=120, blank=True, default="")
    phone = models.CharField(max_length=32, blank=True, default="")
    account_status = models.CharField(
        max_length=20,
        choices=AccountStatus.choices,
        default=AccountStatus.ACTIVE,
        db_index=True,
    )
    must_change_password = models.BooleanField(default=False)
    password_changed_at = models.DateTimeField(null=True, blank=True)

    def __str__(self) -> str:
        return f"{self.user.get_full_name() or self.user.username} profile"

    @property
    def is_admin_role(self) -> bool:
        return (self.role or "").strip().lower() in {
            "administrator",
            "admin",
            "manager",
        }

    def sync_active_flag(self) -> None:
        """Keep User.is_active aligned with soft account status."""
        should_be_active = self.account_status == AccountStatus.ACTIVE
        if self.user.is_active != should_be_active:
            self.user.is_active = should_be_active
            self.user.save(update_fields=["is_active"])


class PasswordResetOTP(models.Model):
    """Hashed one-time verification codes for password reset."""

    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="password_reset_otps",
        null=True,
        blank=True,
    )
    email = models.EmailField(db_index=True)
    code_hash = models.CharField(max_length=128)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    used = models.BooleanField(default=False)
    used_at = models.DateTimeField(null=True, blank=True)
    attempt_count = models.PositiveSmallIntegerField(default=0)
    max_attempts = models.PositiveSmallIntegerField(default=5)
    request_ip = models.GenericIPAddressField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"OTP for {self.email} ({'used' if self.used else 'active'})"

    @property
    def is_expired(self) -> bool:
        return timezone.now() >= self.expires_at

    @property
    def is_locked(self) -> bool:
        return self.attempt_count >= self.max_attempts

    @property
    def is_valid(self) -> bool:
        return not self.used and not self.is_expired and not self.is_locked


class PasswordResetToken(models.Model):
    """Short-lived token issued after successful OTP verification."""

    user = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="password_reset_tokens"
    )
    otp = models.ForeignKey(
        PasswordResetOTP,
        on_delete=models.CASCADE,
        related_name="reset_tokens",
        null=True,
        blank=True,
    )
    token_hash = models.CharField(max_length=128, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    used = models.BooleanField(default=False)
    used_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]

    @property
    def is_expired(self) -> bool:
        return timezone.now() >= self.expires_at

    @property
    def is_valid(self) -> bool:
        return not self.used and not self.is_expired


class AuthRateLimit(models.Model):
    """Persistent counters for forgot-password / OTP rate limits."""

    key = models.CharField(max_length=255, unique=True, db_index=True)
    count = models.PositiveIntegerField(default=0)
    window_started = models.DateTimeField(auto_now_add=True)
    last_request_at = models.DateTimeField(auto_now=True)

    def __str__(self) -> str:
        return f"{self.key} ({self.count})"
