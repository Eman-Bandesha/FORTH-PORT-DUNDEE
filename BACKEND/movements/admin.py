from django.contrib import admin

from .models import Movement


@admin.register(Movement)
class MovementAdmin(admin.ModelAdmin):
    list_display = ("reference_no", "type", "item", "quantity", "date", "requested_by")
    list_filter = ("type", "location")
    search_fields = ("reference_no", "item__code", "item__name", "requested_by")
