from django.db.models import Q
from rest_framework import mixins, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from movements.models import Movement, MovementType
from movements.serializers import MovementSerializer

from .filters import ItemFilter, apply_item_sort
from .models import Item
from .serializers import ItemCreateSerializer, ItemSerializer, ItemUpdateSerializer


class ItemViewSet(viewsets.ModelViewSet):
    queryset = Item.objects.all()
    lookup_field = "code"
    lookup_value_regex = "[^/]+"
    filterset_class = ItemFilter
    search_fields = ("code", "name", "category", "location", "description")

    def get_serializer_class(self):
        if self.action == "create":
            return ItemCreateSerializer
        if self.action in ("update", "partial_update"):
            return ItemUpdateSerializer
        return ItemSerializer

    def get_queryset(self):
        qs = super().get_queryset()
        search = self.request.query_params.get("search")
        if search:
            qs = qs.filter(
                Q(code__icontains=search)
                | Q(name__icontains=search)
                | Q(category__icontains=search)
                | Q(location__icontains=search)
            )
        sort = self.request.query_params.get("sort")
        return apply_item_sort(qs, sort)

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        item = serializer.save()
        return Response(
            ItemSerializer(item).data, status=status.HTTP_201_CREATED
        )

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop("partial", False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        item = serializer.save()
        return Response(ItemSerializer(item).data)

    @action(detail=False, methods=["get"], url_path="meta/categories")
    def categories(self, request):
        cats = (
            Item.objects.values_list("category", flat=True)
            .distinct()
            .order_by("category")
        )
        return Response({"categories": list(cats)})

    @action(detail=False, methods=["get"], url_path="meta/locations")
    def locations(self, request):
        locs = (
            Item.objects.values_list("location", flat=True)
            .distinct()
            .order_by("location")
        )
        return Response({"locations": list(locs)})

    @action(detail=True, methods=["get"], url_path="check-code")
    def check_code(self, request, code=None):
        exists = Item.objects.filter(code__iexact=code).exists()
        return Response({"code": code, "exists": exists})

    @action(detail=True, methods=["get"])
    def analytics(self, request, code=None):
        item = self.get_object()
        movements = Movement.objects.filter(item=item).order_by("date", "id")
        history = []
        running = 0
        for m in movements:
            delta = m.quantity if m.type == MovementType.STOCK_IN else -m.quantity
            running = m.stock_before + delta
            history.append(
                {
                    "date": m.date,
                    "type": m.type,
                    "quantity": m.quantity,
                    "stock_after": running,
                }
            )
        last_out = (
            Movement.objects.filter(item=item, type=MovementType.STOCK_OUT)
            .order_by("-date")
            .first()
        )
        return Response(
            {
                "item": ItemSerializer(item).data,
                "history": history,
                "last_stock_out": MovementSerializer(last_out).data
                if last_out
                else None,
            }
        )

    @action(detail=True, methods=["get"], url_path="last-stock-out")
    def last_stock_out(self, request, code=None):
        item = self.get_object()
        last_out = (
            Movement.objects.filter(item=item, type=MovementType.STOCK_OUT)
            .order_by("-date")
            .first()
        )
        if not last_out:
            return Response({"label": None, "movement": None})
        label = f"{last_out.quantity} {item.unit} · {last_out.date.strftime('%d %b %Y')}"
        return Response(
            {"label": label, "movement": MovementSerializer(last_out).data}
        )
