from rest_framework.response import Response
from rest_framework.views import APIView

from inventory.models import Item, StockStatus
from inventory.serializers import ItemSerializer


class NotificationListView(APIView):
    """
    Low-stock and out-of-stock items for the notifications / reorder screens.
    """

    def get(self, request):
        sort = request.query_params.get("sort", "name_asc")
        items = [
            i
            for i in Item.objects.all()
            if i.status in (StockStatus.LOW_STOCK, StockStatus.OUT_OF_STOCK)
        ]
        if sort == "name_desc":
            items.sort(key=lambda x: x.name, reverse=True)
        elif sort == "qty_high_low":
            items.sort(key=lambda x: x.quantity, reverse=True)
        elif sort == "qty_low_high":
            items.sort(key=lambda x: x.quantity)
        else:
            items.sort(key=lambda x: x.name)
        return Response(
            {
                "count": len(items),
                "results": ItemSerializer(items, many=True).data,
            }
        )
