from django.db import models


class StockStatus(models.TextChoices):
    IN_STOCK = "in_stock", "In stock"
    LOW_STOCK = "low_stock", "Low stock"
    OUT_OF_STOCK = "out_of_stock", "Out of stock"


def compute_stock_status(quantity: int, reorder_level: int) -> str:
    if quantity <= 0:
        return StockStatus.OUT_OF_STOCK
    if quantity <= reorder_level:
        return StockStatus.LOW_STOCK
    return StockStatus.IN_STOCK


class Item(models.Model):
    code = models.CharField(max_length=32, unique=True, db_index=True)
    name = models.CharField(max_length=255)
    image = models.URLField(blank=True, default="")
    quantity = models.PositiveIntegerField(default=0)
    category = models.CharField(max_length=120, db_index=True)
    unit = models.CharField(max_length=32, default="Each")
    reorder_level = models.PositiveIntegerField(default=0)
    location = models.CharField(max_length=120, db_index=True)
    description = models.TextField(blank=True, default="")
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["name"]

    def __str__(self) -> str:
        return f"{self.code} — {self.name}"

    @property
    def status(self) -> str:
        return compute_stock_status(self.quantity, self.reorder_level)

    def refresh_quantity_from_movements(self) -> None:
        """Optional helper if you rebuild stock from ledger."""
        from movements.models import Movement, MovementType

        stock = 0
        for m in Movement.objects.filter(item=self).order_by("date", "id"):
            if m.type == MovementType.STOCK_IN:
                stock += m.quantity
            else:
                stock -= m.quantity
        self.quantity = max(0, stock)
        self.save(update_fields=["quantity", "updated_at"])
