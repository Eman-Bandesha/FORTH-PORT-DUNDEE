"""
Tests for staff-only auth, OTP reset, inactive users, and JWT revocation.
"""
from datetime import timedelta
from unittest.mock import patch

from django.contrib.auth.models import User
from django.core import mail
from django.test import TestCase, override_settings
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework_simplejwt.token_blacklist.models import BlacklistedToken, OutstandingToken
from rest_framework_simplejwt.tokens import RefreshToken

from accounts.models import AccountStatus, PasswordResetOTP, PasswordResetToken, UserProfile
from accounts.security import create_otp_for_user, create_reset_token, hash_secret, sha256_hex


@override_settings(
    EMAIL_BACKEND="django.core.mail.backends.locmem.EmailBackend",
    PASSWORD_RESET_RESEND_COOLDOWN_SECONDS=0,
    EXPOSE_OTP_IN_DEBUG=False,
)
class AuthSecurityTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.admin = User.objects.create_user(
            username="admin",
            email="admin@forthports.com",
            password="AdminPass123!",
            first_name="Admin",
            last_name="User",
            is_active=True,
        )
        UserProfile.objects.create(
            user=self.admin, role="Administrator", account_status=AccountStatus.ACTIVE
        )
        self.staff = User.objects.create_user(
            username="jsmith",
            email="john.smith@forthports.com",
            password="StaffPass123!",
            first_name="John",
            last_name="Smith",
            is_active=True,
        )
        UserProfile.objects.create(
            user=self.staff, role="Staff", account_status=AccountStatus.ACTIVE
        )

    def test_public_register_disabled(self):
        res = self.client.post(
            "/api/v1/auth/register/",
            {
                "username": "newbie",
                "email": "n@example.com",
                "password": "Password123!",
            },
            format="json",
        )
        self.assertEqual(res.status_code, 403)

    def test_login_success_and_must_change_flag(self):
        profile = self.staff.profile
        profile.must_change_password = True
        profile.save()
        res = self.client.post(
            "/api/v1/auth/login/",
            {"username": "jsmith", "password": "StaffPass123!"},
            format="json",
        )
        self.assertEqual(res.status_code, 200)
        self.assertTrue(res.data["must_change_password"])
        self.assertIn("access", res.data["tokens"])

    def test_inactive_user_cannot_login(self):
        self.staff.is_active = False
        self.staff.save()
        self.staff.profile.account_status = AccountStatus.DEACTIVATED
        self.staff.profile.save()
        res = self.client.post(
            "/api/v1/auth/login/",
            {"username": "jsmith", "password": "StaffPass123!"},
            format="json",
        )
        self.assertEqual(res.status_code, 403)
        self.assertIn("inactive", res.data["detail"].lower())

    def test_forgot_password_generic_response_and_email(self):
        res = self.client.post(
            "/api/v1/auth/password/forgot/",
            {"email": "john.smith@forthports.com"},
            format="json",
        )
        self.assertEqual(res.status_code, 200)
        self.assertIn("If an active account exists", res.data["detail"])
        self.assertEqual(len(mail.outbox), 1)
        self.assertIn("verification code", mail.outbox[0].body.lower())
        self.assertTrue(
            PasswordResetOTP.objects.filter(user=self.staff, used=False).exists()
        )

    def test_forgot_password_unknown_user_still_generic(self):
        res = self.client.post(
            "/api/v1/auth/password/forgot/",
            {"username": "nosuchuser"},
            format="json",
        )
        self.assertEqual(res.status_code, 200)
        self.assertIn("If an active account exists", res.data["detail"])
        self.assertEqual(len(mail.outbox), 0)

    def test_forgot_password_inactive_sends_no_code(self):
        self.staff.is_active = False
        self.staff.save()
        self.staff.profile.account_status = AccountStatus.SUSPENDED
        self.staff.profile.save()
        res = self.client.post(
            "/api/v1/auth/password/forgot/",
            {"email": "john.smith@forthports.com"},
            format="json",
        )
        self.assertEqual(res.status_code, 200)
        self.assertEqual(len(mail.outbox), 0)

    def test_successful_otp_verify_and_reset(self):
        otp, code = create_otp_for_user(self.staff)
        verify = self.client.post(
            "/api/v1/auth/password/verify-otp/",
            {"email": "john.smith@forthports.com", "otp": code},
            format="json",
        )
        self.assertEqual(verify.status_code, 200)
        self.assertTrue(verify.data["valid"])
        reset_token = verify.data["reset_token"]

        otp.refresh_from_db()
        self.assertTrue(otp.used)

        # Issue a refresh token then ensure it is revoked after reset
        refresh = RefreshToken.for_user(self.staff)
        self.assertTrue(OutstandingToken.objects.filter(user=self.staff).exists())

        reset = self.client.post(
            "/api/v1/auth/password/reset/",
            {
                "reset_token": reset_token,
                "new_password": "NewSecurePass1!",
                "confirm_password": "NewSecurePass1!",
            },
            format="json",
        )
        self.assertEqual(reset.status_code, 200)
        self.staff.refresh_from_db()
        self.assertTrue(self.staff.check_password("NewSecurePass1!"))
        self.assertFalse(self.staff.profile.must_change_password)
        self.assertTrue(BlacklistedToken.objects.filter(token__user=self.staff).exists())
        self.assertTrue(any("password was changed" in m.subject.lower() for m in mail.outbox))

        # Token reuse blocked
        reuse = self.client.post(
            "/api/v1/auth/password/reset/",
            {
                "reset_token": reset_token,
                "new_password": "AnotherPass1!",
                "confirm_password": "AnotherPass1!",
            },
            format="json",
        )
        self.assertEqual(reuse.status_code, 400)

    def test_expired_otp_rejected(self):
        otp, code = create_otp_for_user(self.staff)
        PasswordResetOTP.objects.filter(pk=otp.pk).update(
            expires_at=timezone.now() - timedelta(minutes=1)
        )
        res = self.client.post(
            "/api/v1/auth/password/verify-otp/",
            {"username": "jsmith", "otp": code},
            format="json",
        )
        self.assertEqual(res.status_code, 400)
        self.assertFalse(res.data.get("valid", True))

    def test_incorrect_otp_and_lockout(self):
        create_otp_for_user(self.staff)
        for i in range(5):
            res = self.client.post(
                "/api/v1/auth/password/verify-otp/",
                {"email": "john.smith@forthports.com", "otp": "000000"},
                format="json",
            )
            self.assertEqual(res.status_code, 400)
        record = PasswordResetOTP.objects.filter(user=self.staff).latest("created_at")
        self.assertTrue(record.is_locked)

    def test_otp_cannot_be_reused(self):
        otp, code = create_otp_for_user(self.staff)
        first = self.client.post(
            "/api/v1/auth/password/verify-otp/",
            {"email": "john.smith@forthports.com", "otp": code},
            format="json",
        )
        self.assertEqual(first.status_code, 200)
        second = self.client.post(
            "/api/v1/auth/password/verify-otp/",
            {"email": "john.smith@forthports.com", "otp": code},
            format="json",
        )
        self.assertEqual(second.status_code, 400)

    def test_admin_create_user_generates_temp_password_email(self):
        self.client.force_authenticate(user=self.admin)
        res = self.client.post(
            "/api/v1/users/",
            {
                "first_name": "Emma",
                "last_name": "Brown",
                "email": "emma.brown@forthports.com",
                "username": "ebrown",
                "role": "Supervisor",
                "generate_temporary_password": True,
                "send_setup_email": True,
            },
            format="json",
        )
        self.assertEqual(res.status_code, 201)
        created = User.objects.get(username="ebrown")
        self.assertTrue(created.profile.must_change_password)
        self.assertEqual(len(mail.outbox), 1)
        self.assertIn("Temporary password", mail.outbox[0].body)

    def test_non_admin_cannot_manage_users(self):
        self.client.force_authenticate(user=self.staff)
        res = self.client.get("/api/v1/users/")
        self.assertEqual(res.status_code, 403)

    def test_soft_deactivate_keeps_user_row(self):
        self.client.force_authenticate(user=self.admin)
        res = self.client.delete(f"/api/v1/users/{self.staff.pk}/")
        self.assertEqual(res.status_code, 200)
        self.staff.refresh_from_db()
        self.assertFalse(self.staff.is_active)
        self.assertEqual(self.staff.profile.account_status, AccountStatus.DEACTIVATED)
        self.assertTrue(User.objects.filter(pk=self.staff.pk).exists())

    def test_change_password_revokes_sessions(self):
        RefreshToken.for_user(self.staff)
        self.client.force_authenticate(user=self.staff)
        res = self.client.post(
            "/api/v1/auth/password/change/",
            {
                "current_password": "StaffPass123!",
                "new_password": "ChangedPass123!",
                "confirm_password": "ChangedPass123!",
            },
            format="json",
        )
        self.assertEqual(res.status_code, 200)
        self.assertIn("tokens", res.data)
        self.assertTrue(BlacklistedToken.objects.filter(token__user=self.staff).exists())
