import django_filters
from django.db.models import Q, QuerySet
from django.utils import timezone

from .models import Movement, MovementType


class MovementFilter(django_filters.FilterSet):
    type = django_filters.ChoiceFilter(choices=MovementType.choices)
    location = django_filters.CharFilter(field_name="location", lookup_expr="iexact")
    from_date = django_filters.DateTimeFilter(field_name="date", lookup_expr="gte")
    to_date = django_filters.DateTimeFilter(field_name="date", lookup_expr="lte")

    class Meta:
        model = Movement
        fields = ("type", "location")


SORT_MAP = {
    "newest_first": "-date",
    "oldest_first": "date",
    "qty_high_low": "-quantity",
    "qty_low_high": "quantity",
}


def apply_movement_sort(queryset: QuerySet, sort: str | None) -> QuerySet:
    return queryset.order_by(SORT_MAP.get(sort or "newest_first", "-date"))


def stock_out_today_count(user=None) -> int:
    from .scope import movements_visible_to

    today = timezone.localdate()
    qs = Movement.objects.filter(type=MovementType.STOCK_OUT, date__date=today)
    if user is not None:
        qs = movements_visible_to(user, qs)
    return qs.count()
