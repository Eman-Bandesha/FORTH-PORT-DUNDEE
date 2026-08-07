from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from django.utils import timezone

from accounts.models import UserProfile
from inventory.models import Item
from movements.models import Movement, MovementType


class Command(BaseCommand):
    help = "Load demo users, items, and movements matching the Flutter seed data."

    def handle(self, *args, **options):
        self._ensure_user(
            username="eman",
            email="eman@gmail.com",
            password="123456",
            first_name="Eman",
            last_name="",
            role="Administrator",
            department="Maintenance Team",
            phone="",
            reset_password=True,
        )
        self._ensure_user(
            username="johndoe",
            email="john.doe@forthports.demo",
            password="Password123!",
            first_name="John",
            last_name="Doe",
            role="Store Staff",
            department="Maintenance Team",
            phone="+44 7700 900123",
            reset_password=False,
        )

        items_data = [
            ("PRN13DGTF", "Brush Stiff 130MM", 35, "Tools", "Each", 10, "Main Warehouse"),
            ("CGM20GREY", "Cable Gland M20 Grey", 120, "Electrical", "Each", 30, "Main Warehouse"),
            ("CT300X48", "Cable Tie 300MM X 4.8MM", 50, "Electrical", "Pack", 60, "Store A"),
            ("CLNR750", "Cleaner Degreaser 750ML", 50, "Cleaning", "Bottle", 15, "Main Warehouse"),
            ("GNLRG", "Gloves Nitrile Large (Pair)", 0, "PPE", "Pair", 25, "Store B"),
            ("PRN5DTF", "Brush Stiff 50MM", 36, "Tools", "Each", 10, "Main Warehouse"),
            ("PRN7SOFT", "Brush Soft 75MM", 8, "Tools", "Each", 12, "Store A"),
            ("WBR200", "Wire Brush 200MM", 6, "Tools", "Each", 5, "Main Warehouse"),
            ("PBS3PCS", "Paint Brush Set (3 PCS)", 22, "Tools", "Set", 8, "Store B"),
            ("WD400", "WD-40 Lubricant 400ML", 7, "Cleaning", "Bottle", 12, "Main Warehouse"),
        ]
        for code, name, qty, cat, unit, reorder, loc in items_data:
            Item.objects.update_or_create(
                code=code,
                defaults={
                    "name": name,
                    "quantity": qty,
                    "category": cat,
                    "unit": unit,
                    "reorder_level": reorder,
                    "location": loc,
                    "description": name,
                    "image": "",
                },
            )

        if Movement.objects.exists():
            self.stdout.write(self.style.WARNING("Movements already seeded; skipping movements."))
        else:
            self._seed_movements()

        self.stdout.write(
            self.style.SUCCESS(
                "Demo data loaded. Login: eman@gmail.com / 123456 "
                "(or johndoe / Password123!)"
            )
        )

    def _ensure_user(
        self,
        *,
        username: str,
        email: str,
        password: str,
        first_name: str,
        last_name: str,
        role: str,
        department: str,
        phone: str,
        reset_password: bool,
    ) -> None:
        user, created = User.objects.get_or_create(
            username=username,
            defaults={
                "email": email,
                "first_name": first_name,
                "last_name": last_name,
            },
        )
        if not created and user.email != email:
            user.email = email
            user.first_name = first_name
            user.last_name = last_name
            user.save()
        if created or reset_password:
            user.set_password(password)
            user.save()
        UserProfile.objects.update_or_create(
            user=user,
            defaults={
                "role": role,
                "department": department,
                "phone": phone,
                "account_status": "active",
            },
        )

    def _seed_movements(self):
        def item(code):
            return Item.objects.get(code=code)

        seeds = [
            (MovementType.STOCK_IN, "PRN13DGTF", 25, "2024-05-20T10:30:00", "WO78901", "John Doe", "Main Warehouse", 10),
            (MovementType.STOCK_IN, "CGM20GREY", 120, "2024-05-20T09:15:00", "WO78902", "Sarah Lee", "Main Warehouse", 0),
            (MovementType.STOCK_OUT, "PRN13DGTF", 8, "2024-05-20T11:00:00", "WO79001", "John Doe", "Main Warehouse", 35, "Maintenance work order"),
            (MovementType.STOCK_OUT, "CT300X48", 12, "2024-05-19T14:30:00", "WO79002", "Tom Brown", "Store A", 50, "Project issue"),
        ]
        for row in seeds:
            if len(row) == 9:
                mtype, code, qty, dt, ref, by, loc, before, reason = row
            else:
                mtype, code, qty, dt, ref, by, loc, before = row
                reason = ""
            Movement.objects.create(
                type=mtype,
                item=item(code),
                quantity=qty,
                date=timezone.datetime.fromisoformat(dt).replace(tzinfo=timezone.get_current_timezone()),
                reference_no=ref,
                requested_by=by,
                location=loc,
                stock_before=before,
                notes="",
                reason=reason,
            )
