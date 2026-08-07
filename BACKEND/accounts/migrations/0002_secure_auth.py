import django.db.models.deletion
import django.utils.timezone
from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("accounts", "0001_initial"),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name="AuthRateLimit",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("key", models.CharField(db_index=True, max_length=255, unique=True)),
                ("count", models.PositiveIntegerField(default=0)),
                ("window_started", models.DateTimeField(auto_now_add=True)),
                ("last_request_at", models.DateTimeField(auto_now=True)),
            ],
        ),
        migrations.AddField(
            model_name="userprofile",
            name="account_status",
            field=models.CharField(
                choices=[
                    ("active", "Active"),
                    ("suspended", "Suspended"),
                    ("deactivated", "Deactivated"),
                ],
                db_index=True,
                default="active",
                max_length=20,
            ),
        ),
        migrations.AddField(
            model_name="userprofile",
            name="must_change_password",
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name="userprofile",
            name="password_changed_at",
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AlterField(
            model_name="userprofile",
            name="department",
            field=models.CharField(blank=True, default="", max_length=120),
        ),
        migrations.AlterField(
            model_name="userprofile",
            name="role",
            field=models.CharField(default="Staff", max_length=120),
        ),
        # Rebuild PasswordResetOTP for hashed codes
        migrations.DeleteModel(name="PasswordResetOTP"),
        migrations.CreateModel(
            name="PasswordResetOTP",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("email", models.EmailField(db_index=True, max_length=254)),
                ("code_hash", models.CharField(max_length=128)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("expires_at", models.DateTimeField()),
                ("used", models.BooleanField(default=False)),
                ("used_at", models.DateTimeField(blank=True, null=True)),
                ("attempt_count", models.PositiveSmallIntegerField(default=0)),
                ("max_attempts", models.PositiveSmallIntegerField(default=5)),
                (
                    "request_ip",
                    models.GenericIPAddressField(blank=True, null=True),
                ),
                (
                    "user",
                    models.ForeignKey(
                        blank=True,
                        null=True,
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="password_reset_otps",
                        to=settings.AUTH_USER_MODEL,
                    ),
                ),
            ],
            options={"ordering": ["-created_at"]},
        ),
        migrations.CreateModel(
            name="PasswordResetToken",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("token_hash", models.CharField(max_length=128, unique=True)),
                ("created_at", models.DateTimeField(auto_now_add=True)),
                ("expires_at", models.DateTimeField()),
                ("used", models.BooleanField(default=False)),
                ("used_at", models.DateTimeField(blank=True, null=True)),
                (
                    "otp",
                    models.ForeignKey(
                        blank=True,
                        null=True,
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="reset_tokens",
                        to="accounts.passwordresetotp",
                    ),
                ),
                (
                    "user",
                    models.ForeignKey(
                        on_delete=django.db.models.deletion.CASCADE,
                        related_name="password_reset_tokens",
                        to=settings.AUTH_USER_MODEL,
                    ),
                ),
            ],
            options={"ordering": ["-created_at"]},
        ),
    ]
