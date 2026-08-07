from collections import defaultdict
from datetime import datetime, timedelta

from django.contrib.auth.models import User
from django.db.models import Q
from django.utils import timezone
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.serializers import UserSerializer
from inventory.models import Item, StockStatus
from inventory.serializers import ItemSerializer
from movements.models import Movement, MovementType

from .exporters import stock_movement_export, stock_summary_export, users_export


def _items(location: str | None = None, category: str | None = None):
    qs = Item.objects.all()
    if location:
        qs = qs.filter(location__iexact=location)
    if category:
        qs = qs.filter(category__iexact=category)
    return qs


def _ranked(totals: dict[str, int]):
    return sorted(
        [{"name": k, "quantity": v} for k, v in totals.items()],
        key=lambda x: (-x["quantity"], x["name"]),
    )


def _parse_date(value: str | None):
    if not value:
        return None
    try:
        return datetime.strptime(value[:10], "%Y-%m-%d").date()
    except ValueError:
        return None


def build_stock_summary(
    location: str | None = None, category: str | None = None
) -> dict:
    items = list(_items(location=location, category=category))

    total_quantity = sum(i.quantity for i in items)
    low_stock = sum(1 for i in items if i.status == StockStatus.LOW_STOCK)
    out_of_stock = sum(1 for i in items if i.status == StockStatus.OUT_OF_STOCK)

    by_cat: dict[str, dict] = {}
    for i in items:
        key = i.category or "Uncategorised"
        row = by_cat.setdefault(
            key,
            {
                "category": key,
                "total_items": 0,
                "total_quantity": 0,
                "stock_value": 0,
                "out_of_stock": 0,
                "low_stock": 0,
            },
        )
        row["total_items"] += 1
        row["total_quantity"] += i.quantity
        if i.status == StockStatus.OUT_OF_STOCK:
            row["out_of_stock"] += 1
        elif i.status == StockStatus.LOW_STOCK:
            row["low_stock"] += 1

    rows = sorted(by_cat.values(), key=lambda r: (-r["total_quantity"], r["category"]))
    totals = {
        "category": "Total",
        "total_items": len(items),
        "total_quantity": total_quantity,
        "stock_value": 0,
        "out_of_stock": out_of_stock,
        "low_stock": low_stock,
    }

    return {
        "total_items": len(items),
        "total_quantity": total_quantity,
        "total_stock_value": 0,
        "in_stock": sum(1 for i in items if i.status == StockStatus.IN_STOCK),
        "low_stock": low_stock,
        "out_of_stock": out_of_stock,
        "by_category": rows,
        "totals": totals,
    }


def build_stock_movement(
    *,
    location: str | None = None,
    category: str | None = None,
    period: str = "daily",
    from_date=None,
    to_date=None,
) -> dict:
    period = (period or "daily").lower()
    if period not in ("daily", "weekly", "monthly"):
        period = "daily"

    today = timezone.localdate()
    from_date = from_date or (today - timedelta(days=13))
    to_date = to_date or today
    if to_date < from_date:
        from_date, to_date = to_date, from_date

    qs = Movement.objects.filter(
        date__date__gte=from_date, date__date__lte=to_date
    ).select_related("item")
    if location:
        qs = qs.filter(location__iexact=location)
    if category:
        qs = qs.filter(item__category__iexact=category)

    buckets: dict[str, dict] = {}

    def bucket_key(d):
        if period == "weekly":
            start = d - timedelta(days=d.weekday())
            return start.isoformat(), f"W/c {start.strftime('%d %b %Y')}"
        if period == "monthly":
            start = d.replace(day=1)
            return start.isoformat(), start.strftime("%b %Y")
        return d.isoformat(), d.strftime("%d %b %Y")

    for m in qs:
        day = timezone.localtime(m.date).date()
        key, label = bucket_key(day)
        row = buckets.setdefault(
            key,
            {
                "date": key,
                "label": label,
                "stock_in": 0,
                "stock_out": 0,
                "transactions": 0,
            },
        )
        row["transactions"] += 1
        if m.type == MovementType.STOCK_IN:
            row["stock_in"] += m.quantity
        else:
            row["stock_out"] += m.quantity

    series = []
    for key in sorted(buckets.keys()):
        row = buckets[key]
        row["net"] = row["stock_in"] - row["stock_out"]
        series.append(row)

    total_in = sum(r["stock_in"] for r in series)
    total_out = sum(r["stock_out"] for r in series)

    return {
        "period": period,
        "from_date": from_date.isoformat(),
        "to_date": to_date.isoformat(),
        "series": series,
        "totals": {
            "stock_in": total_in,
            "stock_out": total_out,
            "net": total_in - total_out,
            "transactions": sum(r["transactions"] for r in series),
        },
    }


class StockSummaryReportView(APIView):
    def get(self, request):
        location = request.query_params.get("location") or None
        category = request.query_params.get("category") or None
        return Response(build_stock_summary(location=location, category=category))


class LowStockReportView(APIView):
    def get(self, request):
        location = request.query_params.get("location")
        items = [
            i
            for i in _items(location=location)
            if i.status in (StockStatus.LOW_STOCK, StockStatus.OUT_OF_STOCK)
        ]
        items.sort(key=lambda x: (x.quantity, x.name))
        return Response({"count": len(items), "results": ItemSerializer(items, many=True).data})


class ByCategoryReportView(APIView):
    def get(self, request):
        location = request.query_params.get("location")
        totals: dict[str, int] = defaultdict(int)
        for i in _items(location=location):
            totals[i.category] += i.quantity
        return Response({"results": _ranked(totals)})


class ByLocationReportView(APIView):
    def get(self, request):
        totals: dict[str, int] = defaultdict(int)
        for i in Item.objects.all():
            totals[i.location] += i.quantity
        return Response({"results": _ranked(totals)})


class StockInOutReportView(APIView):
    def get(self, request):
        from_date = request.query_params.get("from_date")
        to_date = request.query_params.get("to_date")
        qs = Movement.objects.all()
        if from_date:
            qs = qs.filter(date__date__gte=from_date)
        if to_date:
            qs = qs.filter(date__date__lte=to_date)
        stock_in = sum(m.quantity for m in qs if m.type == MovementType.STOCK_IN)
        stock_out = sum(m.quantity for m in qs if m.type == MovementType.STOCK_OUT)
        return Response(
            {
                "stock_in": stock_in,
                "stock_out": stock_out,
                "net": stock_in - stock_out,
                "transactions": qs.count(),
            }
        )


class StockMovementReportView(APIView):
    """Daily / weekly / monthly stock-in vs stock-out series for admin reports."""

    def get(self, request):
        location = request.query_params.get("location") or None
        category = request.query_params.get("category") or None
        period = request.query_params.get("period") or "daily"
        today = timezone.localdate()
        from_date = _parse_date(request.query_params.get("from_date")) or (
            today - timedelta(days=13)
        )
        to_date = _parse_date(request.query_params.get("to_date")) or today
        return Response(
            build_stock_movement(
                location=location,
                category=category,
                period=period,
                from_date=from_date,
                to_date=to_date,
            )
        )


class IssuedStockReportView(APIView):
    def get(self, request):
        location = request.query_params.get("location")
        qs = Movement.objects.filter(type=MovementType.STOCK_OUT).select_related(
            "item"
        )
        if location:
            qs = qs.filter(location=location)
        by_item: dict[str, int] = defaultdict(int)
        for m in qs:
            by_item[m.item.code] += m.quantity
        results = sorted(
            [{"item_code": k, "quantity": v} for k, v in by_item.items()],
            key=lambda x: -x["quantity"],
        )
        return Response({"results": results})


class ExportReportView(APIView):
    """Generate CSV or PDF downloads for report types."""

    def post(self, request):
        report_type = (request.data.get("report_type") or "stock_summary").lower()
        fmt = (request.data.get("format") or "csv").lower()
        if fmt not in ("csv", "pdf"):
            return Response(
                {"detail": "format must be csv or pdf."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        location = request.data.get("location") or None
        category = request.data.get("category") or None

        if report_type in ("stock_summary", "stock-summary"):
            data = build_stock_summary(location=location, category=category)
            return stock_summary_export(data, fmt)

        if report_type in ("stock_movement", "stock-movement"):
            today = timezone.localdate()
            from_date = _parse_date(request.data.get("from_date")) or (
                today - timedelta(days=13)
            )
            to_date = _parse_date(request.data.get("to_date")) or today
            period = request.data.get("period") or "daily"
            data = build_stock_movement(
                location=location,
                category=category,
                period=period,
                from_date=from_date,
                to_date=to_date,
            )
            return stock_movement_export(data, fmt)

        if report_type in ("users", "user"):
            qs = User.objects.select_related("profile").order_by(
                "first_name", "username"
            )
            search = request.data.get("search")
            if search:
                qs = qs.filter(
                    Q(username__icontains=search)
                    | Q(email__icontains=search)
                    | Q(first_name__icontains=search)
                    | Q(last_name__icontains=search)
                )
            role = request.data.get("role")
            if role:
                qs = qs.filter(profile__role__iexact=role)
            status_param = (request.data.get("status") or "").lower()
            if status_param in ("active", "inactive"):
                qs = qs.filter(is_active=status_param == "active")
            serialized = UserSerializer(qs, many=True).data
            return users_export(list(serialized), fmt)

        return Response(
            {"detail": f"Unknown report_type: {report_type}"},
            status=status.HTTP_400_BAD_REQUEST,
        )
