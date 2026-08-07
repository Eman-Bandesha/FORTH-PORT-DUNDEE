from django.db.models import Q, Sum
from django.utils import timezone
from rest_framework import mixins, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .filters import MovementFilter, apply_movement_sort, stock_out_today_count
from .models import STOCK_OUT_REASONS, Movement, MovementType, next_reference_no
from .scope import movements_visible_to
from .serializers import MovementCreateSerializer, MovementSerializer


class MovementViewSet(
    mixins.ListModelMixin,
    mixins.RetrieveModelMixin,
    mixins.CreateModelMixin,
    viewsets.GenericViewSet,
):
    queryset = Movement.objects.select_related("item", "created_by").all()
    serializer_class = MovementSerializer
    filterset_class = MovementFilter

    def get_serializer_class(self):
        if self.action == "create":
            return MovementCreateSerializer
        return MovementSerializer

    def get_queryset(self):
        qs = movements_visible_to(self.request.user, super().get_queryset())
        search = self.request.query_params.get("search")
        if search:
            qs = qs.filter(
                Q(item__code__icontains=search)
                | Q(item__name__icontains=search)
                | Q(reference_no__icontains=search)
                | Q(requested_by__icontains=search)
            )
        sort = self.request.query_params.get("sort")
        return apply_movement_sort(qs, sort)

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        movement = serializer.save(created_by=request.user)
        return Response(
            MovementSerializer(movement).data, status=status.HTTP_201_CREATED
        )

    @action(detail=False, methods=["get"])
    def reasons(self, request):
        return Response({"reasons": STOCK_OUT_REASONS})

    @action(detail=False, methods=["get"], url_path="next-reference")
    def next_reference(self, request):
        return Response({"reference_no": next_reference_no()})

    @action(detail=False, methods=["get"])
    def summary(self, request):
        now = timezone.now()
        start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        qs = movements_visible_to(
            request.user, Movement.objects.filter(date__gte=start)
        )
        total_in = (
            qs.filter(type=MovementType.STOCK_IN).aggregate(s=Sum("quantity"))["s"]
            or 0
        )
        total_out = (
            qs.filter(type=MovementType.STOCK_OUT).aggregate(s=Sum("quantity"))["s"]
            or 0
        )
        return Response(
            {
                "total_in": total_in,
                "total_out": total_out,
                "transactions": qs.count(),
                "net": total_in - total_out,
                "stock_out_today": stock_out_today_count(user=request.user),
            }
        )

    @action(detail=False, methods=["get"], url_path="recent-stock-out")
    def recent_stock_out(self, request):
        limit = int(request.query_params.get("limit", 5))
        qs = (
            movements_visible_to(
                request.user,
                Movement.objects.filter(type=MovementType.STOCK_OUT),
            )
            .select_related("item")
            .order_by("-date")[:limit]
        )
        return Response(MovementSerializer(qs, many=True).data)
