from django.utils import timezone
from rest_framework import serializers

from inventory.models import Item

from .models import Movement, MovementType, next_reference_no


class MovementSerializer(serializers.ModelSerializer):
    item_name = serializers.CharField(read_only=True)
    item_code = serializers.CharField(read_only=True)
    image = serializers.CharField(read_only=True)
    unit = serializers.CharField(read_only=True)
    change = serializers.IntegerField(read_only=True)
    remaining_stock = serializers.IntegerField(read_only=True)
    date_time_label = serializers.SerializerMethodField()

    class Meta:
        model = Movement
        fields = (
            "id",
            "type",
            "item_name",
            "item_code",
            "image",
            "quantity",
            "date",
            "date_time_label",
            "reference_no",
            "requested_by",
            "location",
            "notes",
            "reason",
            "unit",
            "stock_before",
            "change",
            "remaining_stock",
        )

    def get_date_time_label(self, obj: Movement) -> str:
        local = timezone.localtime(obj.date)
        return local.strftime("%d %b %Y, %I:%M %p").replace(" 0", " ")


class MovementCreateSerializer(serializers.Serializer):
    type = serializers.ChoiceField(choices=MovementType.choices)
    item_code = serializers.CharField()
    quantity = serializers.IntegerField(min_value=1)
    date = serializers.DateTimeField(required=False)
    reference_no = serializers.CharField(required=False, allow_blank=True)
    requested_by = serializers.CharField()
    location = serializers.CharField(required=False, allow_blank=True)
    notes = serializers.CharField(required=False, allow_blank=True, default="")
    reason = serializers.CharField(required=False, allow_blank=True, default="")

    def validate_item_code(self, value: str) -> str:
        if not Item.objects.filter(code__iexact=value.strip()).exists():
            raise serializers.ValidationError("Item not found.")
        return value.strip().upper()

    def validate(self, attrs):
        item = Item.objects.get(code__iexact=attrs["item_code"])
        qty = attrs["quantity"]
        if attrs["type"] == MovementType.STOCK_OUT and item.quantity < qty:
            raise serializers.ValidationError(
                {"quantity": f"Insufficient stock. Available: {item.quantity}."}
            )
        if attrs["type"] == MovementType.STOCK_OUT and not attrs.get("reason"):
            attrs["reason"] = ""
        attrs["item"] = item
        return attrs

    def create(self, validated_data):
        item: Item = validated_data.pop("item")
        validated_data.pop("item_code", None)
        movement_type = validated_data.pop("type")
        qty = validated_data.pop("quantity")
        stock_before = item.quantity
        ref = validated_data.pop("reference_no", None) or next_reference_no()
        date = validated_data.pop("date", None) or timezone.now()
        location = validated_data.pop("location", None) or item.location
        notes = validated_data.pop("notes", "") or ""
        reason = validated_data.pop("reason", "") or ""
        requested_by = validated_data.pop("requested_by")
        created_by = validated_data.pop("created_by", None)
        if created_by is not None and not requested_by.strip():
            full = f"{created_by.first_name} {created_by.last_name}".strip()
            requested_by = full or created_by.username
        movement = Movement.objects.create(
            type=movement_type,
            item=item,
            quantity=qty,
            date=date,
            reference_no=ref,
            stock_before=stock_before,
            location=location,
            notes=notes,
            reason=reason,
            requested_by=requested_by,
            created_by=created_by,
        )
        if movement_type == MovementType.STOCK_IN:
            item.quantity = stock_before + qty
        else:
            item.quantity = max(0, stock_before - qty)
        item.save(update_fields=["quantity", "updated_at"])
        return movement
