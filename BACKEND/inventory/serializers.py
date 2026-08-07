from django.utils import timezone
from rest_framework import serializers

from inventory.models import Item, StockStatus


class ItemSerializer(serializers.ModelSerializer):
    status = serializers.CharField(read_only=True)
    last_updated = serializers.SerializerMethodField()

    class Meta:
        model = Item
        fields = (
            "code",
            "name",
            "image",
            "status",
            "quantity",
            "category",
            "unit",
            "reorder_level",
            "location",
            "description",
            "last_updated",
        )
        read_only_fields = ("status", "last_updated")

    def get_last_updated(self, obj: Item) -> str:
        local = timezone.localtime(obj.updated_at)
        return local.strftime("%d %b %Y, %I:%M %p").replace(" 0", " ")


class ItemCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Item
        fields = (
            "code",
            "name",
            "image",
            "quantity",
            "category",
            "unit",
            "reorder_level",
            "location",
            "description",
        )

    def validate_code(self, value: str) -> str:
        code = value.strip().upper()
        if Item.objects.filter(code__iexact=code).exists():
            raise serializers.ValidationError("An item with this code already exists.")
        return code


class ItemUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Item
        fields = (
            "name",
            "image",
            "quantity",
            "category",
            "unit",
            "reorder_level",
            "location",
            "description",
        )


class ItemListQuerySerializer(serializers.Serializer):
    """Documents query params for Postman; validation is in the viewset."""

    search = serializers.CharField(required=False)
    status = serializers.MultipleChoiceField(
        choices=StockStatus.choices, required=False
    )
    category = serializers.CharField(required=False)
    location = serializers.CharField(required=False)
    sort = serializers.ChoiceField(
        choices=(
            ("name_asc", "name_asc"),
            ("name_desc", "name_desc"),
            ("qty_high_low", "qty_high_low"),
            ("qty_low_high", "qty_low_high"),
        ),
        required=False,
        default="name_asc",
    )
    page = serializers.IntegerField(required=False)
    page_size = serializers.IntegerField(required=False)
