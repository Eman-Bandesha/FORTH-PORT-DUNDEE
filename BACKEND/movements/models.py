import uuid

from django.conf import settings
from django.db import models

from inventory.models import Item


class MovementType(models.TextChoices):
    STOCK_IN = "stock_in", "Stock in"
    STOCK_OUT = "stock_out", "Stock out"


STOCK_OUT_REASONS = [
    "Maintenance work order",
    "Breakdown / emergency repair",
    "Routine inspection",
    "Project issue",
    "Transfer to another site",
    "Damaged / write-off",
    "Other",
]


class Movement(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    type = models.CharField(max_length=16, choices=MovementType.choices)
    item = models.ForeignKey(
        Item, on_delete=models.PROTECT, related_name="movements"
    )
    quantity = models.PositiveIntegerField()
    date = models.DateTimeField()
    reference_no = models.CharField(max_length=64, db_index=True)
    requested_by = models.CharField(max_length=120)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="movements",
    )
    location = models.CharField(max_length=120)
    notes = models.TextField(blank=True, default="")
    reason = models.CharField(max_length=120, blank=True, default="")
    stock_before = models.PositiveIntegerField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-date", "-created_at"]

    @property
    def item_name(self) -> str:
        return self.item.name

    @property
    def item_code(self) -> str:
        return self.item.code

    @property
    def image(self) -> str:
        return self.item.image

    @property
    def unit(self) -> str:
        return self.item.unit

    @property
    def change(self) -> int:
        return self.quantity if self.type == MovementType.STOCK_IN else -self.quantity

    @property
    def remaining_stock(self) -> int:
        return self.stock_before + self.change


def next_reference_no() -> str:
    last = (
        Movement.objects.filter(reference_no__startswith="WO")
        .order_by("-reference_no")
        .values_list("reference_no", flat=True)
        .first()
    )
    if not last:
        return "WO78901"
    try:
        num = int(last.replace("WO", "")) + 1
    except ValueError:
        num = 78901
    return f"WO{num}"
