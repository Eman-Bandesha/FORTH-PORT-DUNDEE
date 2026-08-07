"""
Django settings for Forth Ports Dundee Stock Management API.
"""
from __future__ import annotations

import os
from datetime import timedelta
from pathlib import Path

from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / ".env")

SECRET_KEY = os.environ.get(
    "DJANGO_SECRET_KEY",
    "django-insecure-dev-only-change-in-production",
)

DEBUG = os.environ.get("DJANGO_DEBUG", "true").lower() in {"1", "true", "yes"}

ALLOWED_HOSTS = [
    h.strip()
    for h in os.environ.get(
        "DJANGO_ALLOWED_HOSTS",
        "localhost,127.0.0.1,10.0.2.2,testserver",
    ).split(",")
    if h.strip()
]

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "corsheaders",
    "rest_framework",
    "rest_framework_simplejwt",
    "rest_framework_simplejwt.token_blacklist",
    "django_filters",
    "accounts",
    "inventory",
    "movements",
    "dashboard",
    "reports",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
                "django.template.context_processors.request",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"

# Database: DATABASE_URL (Render/Neon) → POSTGRES_* → SQLite (local).
_database_url = os.environ.get("DATABASE_URL", "").strip()
if _database_url:
    import dj_database_url

    DATABASES = {
        "default": dj_database_url.config(
            default=_database_url,
            conn_max_age=600,
        )
    }
elif os.environ.get("POSTGRES_DB"):
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.postgresql",
            "NAME": os.environ.get("POSTGRES_DB", "forthports"),
            "USER": os.environ.get("POSTGRES_USER", "forthports"),
            "PASSWORD": os.environ.get("POSTGRES_PASSWORD", ""),
            "HOST": os.environ.get("POSTGRES_HOST", "localhost"),
            "PORT": os.environ.get("POSTGRES_PORT", "5432"),
        }
    }
else:
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.sqlite3",
            "NAME": BASE_DIR / "db.sqlite3",
        }
    }

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {
        "NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
        "OPTIONS": {"min_length": 8},
    },
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

LANGUAGE_CODE = "en-gb"
TIME_ZONE = "Europe/London"
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"
STATIC_ROOT = BASE_DIR / "staticfiles"
STORAGES = {
    "default": {
        "BACKEND": "django.core.files.storage.FileSystemStorage",
    },
    "staticfiles": {
        "BACKEND": "whitenoise.storage.CompressedStaticFilesStorage",
    },
}
MEDIA_URL = "media/"
MEDIA_ROOT = BASE_DIR / "media"
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

CORS_ALLOW_ALL_ORIGINS = DEBUG
if not DEBUG:
    CORS_ALLOWED_ORIGINS = [
        o.strip()
        for o in os.environ.get("CORS_ALLOWED_ORIGINS", "").split(",")
        if o.strip()
    ]
    CORS_ALLOWED_ORIGIN_REGEXES = [
        r"^https://.*\.vercel\.app$",
        r"^https://.*\.netlify\.app$",
    ]
    _extra_regex = os.environ.get("CORS_ALLOWED_ORIGIN_REGEXES", "").strip()
    if _extra_regex:
        CORS_ALLOWED_ORIGIN_REGEXES.extend(
            [p.strip() for p in _extra_regex.split(",") if p.strip()]
        )

CSRF_TRUSTED_ORIGINS = [
    o.strip()
    for o in os.environ.get("CSRF_TRUSTED_ORIGINS", "").split(",")
    if o.strip()
]

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": (
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ),
    "DEFAULT_PERMISSION_CLASSES": ("rest_framework.permissions.IsAuthenticated",),
    "DEFAULT_FILTER_BACKENDS": (
        "django_filters.rest_framework.DjangoFilterBackend",
        "rest_framework.filters.SearchFilter",
        "rest_framework.filters.OrderingFilter",
    ),
    "DEFAULT_PAGINATION_CLASS": "config.pagination.StandardResultsPagination",
    "PAGE_SIZE": 20,
    "DATETIME_FORMAT": "%Y-%m-%dT%H:%M:%S%z",
    "DEFAULT_THROTTLE_RATES": {
        "anon": "60/min",
        "user": "120/min",
    },
}

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(
        minutes=int(os.environ.get("JWT_ACCESS_MINUTES", "30"))
    ),
    "REFRESH_TOKEN_LIFETIME": timedelta(
        days=int(os.environ.get("JWT_REFRESH_DAYS", "7"))
    ),
    "ROTATE_REFRESH_TOKENS": True,
    "BLACKLIST_AFTER_ROTATION": True,
    "UPDATE_LAST_LOGIN": False,
}

# --- Email (Brevo SMTP when credentials are set; otherwise console) ---
# Prefer real SMTP whenever Brevo login + key exist, even during local DEBUG.
_brevo_user = os.environ.get("BREVO_SMTP_USERNAME", "").strip()
_brevo_key = os.environ.get("BREVO_SMTP_KEY", "").strip()
_use_smtp = bool(_brevo_user and _brevo_key)

EMAIL_BACKEND = os.environ.get(
    "EMAIL_BACKEND",
    "django.core.mail.backends.smtp.EmailBackend"
    if _use_smtp
    else "django.core.mail.backends.console.EmailBackend",
)
EMAIL_HOST = os.environ.get("EMAIL_HOST", "smtp-relay.brevo.com")
EMAIL_PORT = int(os.environ.get("EMAIL_PORT", "587"))
EMAIL_USE_TLS = os.environ.get("EMAIL_USE_TLS", "true").lower() in {"1", "true", "yes"}
EMAIL_HOST_USER = _brevo_user
EMAIL_HOST_PASSWORD = _brevo_key
DEFAULT_FROM_EMAIL = os.environ.get(
    "DEFAULT_FROM_EMAIL",
    "Forth Ports Dundee <noreply@localhost>",
)
# Brevo transactional HTTP API (preferred over SMTP when set)
BREVO_API_KEY = os.environ.get("BREVO_API_KEY", "").strip()
# Optional: log which backend is active (never logs secrets)
if _use_smtp:
    import logging as _logging

    _logging.getLogger("accounts").info(
        "Email: Brevo SMTP enabled (%s:%s)", EMAIL_HOST, EMAIL_PORT
    )
else:
    import logging as _logging

    _logging.getLogger("accounts").warning(
        "Email: console only — set BREVO_SMTP_USERNAME and BREVO_SMTP_KEY in .env to send real emails"
    )

# Password-reset security
PASSWORD_RESET_OTP_MINUTES = int(os.environ.get("PASSWORD_RESET_OTP_MINUTES", "10"))
PASSWORD_RESET_TOKEN_MINUTES = int(os.environ.get("PASSWORD_RESET_TOKEN_MINUTES", "15"))
PASSWORD_RESET_MAX_ATTEMPTS = int(os.environ.get("PASSWORD_RESET_MAX_ATTEMPTS", "5"))
PASSWORD_RESET_RESEND_COOLDOWN_SECONDS = int(
    os.environ.get("PASSWORD_RESET_RESEND_COOLDOWN_SECONDS", "60")
)
PASSWORD_RESET_IP_RATE_LIMIT = int(os.environ.get("PASSWORD_RESET_IP_RATE_LIMIT", "10"))
PASSWORD_RESET_USER_RATE_LIMIT = int(
    os.environ.get("PASSWORD_RESET_USER_RATE_LIMIT", "5")
)
PASSWORD_RESET_RATE_WINDOW_SECONDS = int(
    os.environ.get("PASSWORD_RESET_RATE_WINDOW_SECONDS", "3600")
)
# Never expose OTP outside DEBUG + explicit flag
EXPOSE_OTP_IN_DEBUG = os.environ.get("EXPOSE_OTP_IN_DEBUG", "false").lower() in {
    "1",
    "true",
    "yes",
}

if not DEBUG:
    SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_SSL_REDIRECT = os.environ.get("SECURE_SSL_REDIRECT", "true").lower() in {
        "1",
        "true",
        "yes",
    }

LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "handlers": {
        "console": {"class": "logging.StreamHandler"},
    },
    "loggers": {
        "accounts": {"handlers": ["console"], "level": "INFO"},
    },
}
