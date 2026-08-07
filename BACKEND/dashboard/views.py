from collections import defaultdict
from datetime import timedelta

from django.db.models import Sum
from django.utils import timezone
from rest_framework.response import Response
from rest_framework.views import APIView

from inventory.models import Item, StockStatus
from inventory.serializers import ItemSerializer
from movements.filters import stock_out_today_count
from movements.models import Movement, MovementType
from movements.scope import movements_visible_to
from movements.serializers import MovementSerializer


class DashboardStatsView(APIView):
    def get(self, request):
        items = list(Item.objects.all())
        in_stock = low_stock = out_of_stock = 0
        total_quantity = 0
        by_category: dict[str, int] = defaultdict(int)

        for item in items:
            total_quantity += item.quantity
            by_category[item.category or "Uncategorised"] += item.quantity
            if item.status == StockStatus.IN_STOCK:
                in_stock += 1
            elif item.status == StockStatus.LOW_STOCK:
                low_stock += 1
            else:
                out_of_stock += 1

        alerts_count = low_stock + out_of_stock

        visible = movements_visible_to(request.user)
        recent_out = (
            visible.filter(type=MovementType.STOCK_OUT)
            .select_related("item")
            .order_by("-date")[:5]
        )
        recent_in = (
            visible.filter(type=MovementType.STOCK_IN)
            .select_related("item")
            .order_by("-date")[:5]
        )
        alert_items = [
            i
            for i in items
            if i.status in (StockStatus.LOW_STOCK, StockStatus.OUT_OF_STOCK)
        ][:8]

        category_rows = sorted(
            [{"name": name, "quantity": qty} for name, qty in by_category.items()],
            key=lambda row: (-row["quantity"], row["name"]),
        )

        today = timezone.localdate()
        trend_7d = []
        for offset in range(6, -1, -1):
            day = today - timedelta(days=offset)
            day_qs = visible.filter(date__date=day)
            stock_in = (
                day_qs.filter(type=MovementType.STOCK_IN).aggregate(s=Sum("quantity"))[
                    "s"
                ]
                or 0
            )
            stock_out = (
                day_qs.filter(type=MovementType.STOCK_OUT).aggregate(s=Sum("quantity"))[
                    "s"
                ]
                or 0
            )
            trend_7d.append(
                {
                    "date": day.isoformat(),
                    "label": day.strftime("%d %b"),
                    "stock_in": stock_in,
                    "stock_out": stock_out,
                }
            )

        return Response(
            {
                "total_items": len(items),
                "total_quantity": total_quantity,
                "in_stock": in_stock,
                "low_stock": low_stock,
                "out_of_stock": out_of_stock,
                "alerts_count": alerts_count,
                "stock_out_today": stock_out_today_count(user=request.user),
                "near_expiry": 0,
                "recent_stock_out": MovementSerializer(recent_out, many=True).data,
                "recent_stock_in": MovementSerializer(recent_in, many=True).data,
                "alert_items": ItemSerializer(alert_items, many=True).data,
                "by_category": category_rows,
                "trend_7d": trend_7d,
            }
        )
