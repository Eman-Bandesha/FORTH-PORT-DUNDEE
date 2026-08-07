"""Transactional email via Brevo API (preferred) or Django SMTP backend."""
from __future__ import annotations

import json
import logging
import re
import urllib.error
import urllib.request

from django.conf import settings
from django.contrib.auth.models import User
from django.core.mail import send_mail

logger = logging.getLogger(__name__)


def _from_email() -> str:
    return getattr(settings, "DEFAULT_FROM_EMAIL", "noreply@localhost")


def _parse_from(from_value: str) -> tuple[str, str]:
    """Return (name, email) from 'Name <email@x.com>' or bare email."""
    match = re.match(r"^(.*?)\s*<([^>]+)>$", (from_value or "").strip())
    if match:
        name = match.group(1).strip().strip('"') or "Forth Ports Dundee"
        return name, match.group(2).strip()
    email = (from_value or "").strip()
    return "Forth Ports Dundee", email


def _send_via_brevo_api(subject: str, message: str, to_email: str) -> bool:
    api_key = (getattr(settings, "BREVO_API_KEY", None) or "").strip()
    if not api_key or api_key.startswith("paste-"):
        return False

    sender_name, sender_email = _parse_from(_from_email())
    if not sender_email or "@" not in sender_email:
        logger.error("DEFAULT_FROM_EMAIL is missing a valid address")
        return False

    payload = {
        "sender": {"name": sender_name, "email": sender_email},
        "to": [{"email": to_email}],
        "subject": subject,
        "textContent": message,
    }
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        "https://api.brevo.com/v3/smtp/email",
        data=data,
        method="POST",
        headers={
            "accept": "application/json",
            "content-type": "application/json",
            "api-key": api_key,
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            body = resp.read().decode("utf-8", errors="replace")
            logger.info(
                "Brevo API email sent subject=%s to=%s status=%s body=%s",
                subject,
                to_email,
                resp.status,
                body[:200],
            )
            return 200 <= resp.status < 300
    except urllib.error.HTTPError as exc:
        err = exc.read().decode("utf-8", errors="replace")
        logger.error(
            "Brevo API send failed status=%s body=%s", exc.code, err[:500]
        )
        return False
    except Exception:
        logger.exception("Brevo API send failed subject=%s to=%s", subject, to_email)
        return False


def _send_via_smtp(subject: str, message: str, to_email: str) -> bool:
    backend = getattr(settings, "EMAIL_BACKEND", "")
    if "smtp" in backend and (
        not getattr(settings, "EMAIL_HOST_USER", "")
        or not getattr(settings, "EMAIL_HOST_PASSWORD", "")
        or "paste-your-brevo" in (getattr(settings, "EMAIL_HOST_USER", "") or "")
        or "paste-your-brevo" in (getattr(settings, "EMAIL_HOST_PASSWORD", "") or "")
    ):
        logger.error(
            "Brevo SMTP credentials missing/placeholder. "
            "Edit BACKEND/.env then restart the server."
        )
        return False
    try:
        send_mail(
            subject=subject,
            message=message,
            from_email=_from_email(),
            recipient_list=[to_email],
            fail_silently=False,
        )
        logger.info("SMTP email sent subject=%s to=%s", subject, to_email)
        return True
    except Exception:
        logger.exception("SMTP send failed subject=%s to=%s", subject, to_email)
        return False


def send_email(subject: str, message: str, to_email: str) -> bool:
    if not to_email:
        logger.warning("No recipient email; skip send: %s", subject)
        return False

    # Prefer Brevo HTTP API (works when SMTP IP is blocked).
    if _send_via_brevo_api(subject, message, to_email):
        return True

    return _send_via_smtp(subject, message, to_email)


def send_account_setup_email(user: User, temporary_password: str, username: str) -> bool:
    subject = "Your Forth Ports Dundee store account"
    message = (
        f"Hello {user.get_full_name() or username},\n\n"
        f"An administrator has created your staff account for the Forth Ports Dundee "
        f"stock management app.\n\n"
        f"Username: {username}\n"
        f"Temporary password: {temporary_password}\n\n"
        f"Please sign in and change your password immediately. "
        f"You will be asked to set a new password on first login.\n\n"
        f"If you did not expect this email, contact your administrator.\n"
    )
    return send_email(subject, message, user.email)


def send_verification_code_email(user: User, code: str) -> bool:
    minutes = getattr(settings, "PASSWORD_RESET_OTP_MINUTES", 10)
    subject = "Your password reset verification code"
    message = (
        f"Hello {user.get_full_name() or user.username},\n\n"
        f"Your verification code is: {code}\n\n"
        f"This code expires in {minutes} minutes and can only be used once.\n"
        f"If you did not request a password reset, you can ignore this email.\n"
    )
    return send_email(subject, message, user.email)


def send_password_changed_email(user: User) -> bool:
    subject = "Your password was changed"
    message = (
        f"Hello {user.get_full_name() or user.username},\n\n"
        f"Your Forth Ports Dundee account password was changed successfully.\n"
        f"All previous app sessions have been signed out.\n\n"
        f"If you did not make this change, contact your administrator immediately.\n"
    )
    return send_email(subject, message, user.email)


def send_admin_password_reset_email(user: User, temporary_password: str) -> bool:
    subject = "Your password was reset by an administrator"
    message = (
        f"Hello {user.get_full_name() or user.username},\n\n"
        f"An administrator reset your password.\n\n"
        f"Username: {user.username}\n"
        f"Temporary password: {temporary_password}\n\n"
        f"Sign in and change your password when prompted.\n"
    )
    return send_email(subject, message, user.email)
