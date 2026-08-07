from django.urls import include, path
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.urls import users_urlpatterns


class HealthView(APIView):
    permission_classes = (AllowAny,)

    def get(self, request):
        return Response({"status": "ok", "version": "v1"})


urlpatterns = [
    path("health/", HealthView.as_view(), name="health"),
    path("auth/", include("accounts.urls")),
    path("users/", include(users_urlpatterns)),
    path("dashboard/", include("dashboard.urls")),
    path("items/", include("inventory.urls")),
    path("movements/", include("movements.urls")),
    path("notifications/", include("inventory.notification_urls")),
    path("reports/", include("reports.urls")),
]
