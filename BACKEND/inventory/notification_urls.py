from django.urls import path

from .notification_views import NotificationListView

urlpatterns = [
    path("", NotificationListView.as_view(), name="notifications"),
]
