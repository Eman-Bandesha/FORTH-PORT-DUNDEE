from django.urls import path

from .views import (
    ByCategoryReportView,
    ByLocationReportView,
    ExportReportView,
    IssuedStockReportView,
    LowStockReportView,
    StockInOutReportView,
    StockMovementReportView,
    StockSummaryReportView,
)

urlpatterns = [
    path("stock-summary/", StockSummaryReportView.as_view(), name="report-stock-summary"),
    path("stock-movement/", StockMovementReportView.as_view(), name="report-stock-movement"),
    path("low-stock/", LowStockReportView.as_view(), name="report-low-stock"),
    path("by-category/", ByCategoryReportView.as_view(), name="report-by-category"),
    path("by-location/", ByLocationReportView.as_view(), name="report-by-location"),
    path("stock-in-out/", StockInOutReportView.as_view(), name="report-stock-in-out"),
    path("issued-stock/", IssuedStockReportView.as_view(), name="report-issued-stock"),
    path("export/", ExportReportView.as_view(), name="report-export"),
]
