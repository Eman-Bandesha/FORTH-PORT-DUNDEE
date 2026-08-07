from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand
from django.db import IntegrityError

from accounts.models import AccountStatus, UserProfile


class Command(BaseCommand):
    help = (
        "Create or update a Django superuser from env vars "
        "(ADMIN_USERNAME / ADMIN_PASSWORD). Safe to run on every deploy."
    )

    def handle(self, *args, **options):
        import os

        username = (os.environ.get("ADMIN_USERNAME") or "").strip()
        password = os.environ.get("ADMIN_PASSWORD") or ""
        email = (os.environ.get("ADMIN_EMAIL") or f"{username}@localhost").strip()

        if not username or not password:
            self.stdout.write(
                self.style.WARNING(
                    "Skip ensure_superuser: set ADMIN_USERNAME and ADMIN_PASSWORD"
                )
            )
            return

        User = get_user_model()
        user = User.objects.filter(username=username).first()
        if user is None:
            try:
                user = User.objects.create_superuser(
                    username=username,
                    email=email,
                    password=password,
                )
                self.stdout.write(self.style.SUCCESS(f"Created superuser '{username}'"))
            except IntegrityError:
                user = User.objects.get(username=username)
                user.set_password(password)
                user.is_staff = True
                user.is_superuser = True
                user.is_active = True
                user.email = email
                user.save()
                self.stdout.write(
                    self.style.SUCCESS(f"Updated existing user '{username}' to superuser")
                )
        else:
            user.set_password(password)
            user.is_staff = True
            user.is_superuser = True
            user.is_active = True
            if email:
                user.email = email
            user.save()
            self.stdout.write(self.style.SUCCESS(f"Updated superuser '{username}'"))

        UserProfile.objects.update_or_create(
            user=user,
            defaults={
                "role": "Administrator",
                "account_status": AccountStatus.ACTIVE,
            },
        )
