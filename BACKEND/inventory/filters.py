import django_filters
from django.db.models import Q, QuerySet

from .models import Item, StockStatus


class ItemFilter(django_filters.FilterSet):
    status = django_filters.CharFilter(method="filter_status")
    category = django_filters.CharFilter(field_name="category", lookup_expr="iexact")
    location = django_filters.CharFilter(field_name="location", lookup_expr="iexact")

    class Meta:
        model = Item
        fields = ("category", "location")

    def filter_status(self, queryset: QuerySet, name: str, value: str) -> QuerySet:
        if not value:
            return queryset
        parts = [p.strip() for p in value.split(",") if p.strip()]
        if not parts:
            return queryset
        codes = []
        for item in queryset:
            if item.status in parts:
                codes.append(item.code)
        return queryset.filter(code__in=codes)


SORT_MAP = {
    "name_asc": "name",
    "name_desc": "-name",
    "qty_high_low": "-quantity",
    "qty_low_high": "quantity",
}


def apply_item_sort(queryset: QuerySet, sort: str | None) -> QuerySet:
    ordering = SORT_MAP.get(sort or "name_asc", "name")
    return queryset.order_by(ordering)
