from django.contrib import admin

from .models import Item


@admin.register(Item)
class ItemAdmin(admin.ModelAdmin):
    list_display = ("code", "name", "quantity", "category", "location", "reorder_level")
    search_fields = ("code", "name", "category", "location")
