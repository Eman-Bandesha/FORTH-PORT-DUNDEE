import 'package:flutter/foundation.dart';

/// A named bucket with an associated quantity (used for category / location
/// breakdowns and ranked tables).
@immutable
class NamedQuantity {
  const NamedQuantity(this.name, this.quantity);

  final String name;
  final int quantity;
}

/// One day of the stock-movement trend (stock in vs stock out).
@immutable
class TrendDay {
  const TrendDay({
    required this.label,
    required this.stockIn,
    required this.stockOut,
  });

  final String label;
  final int stockIn;
  final int stockOut;
}

/// Aggregated headline figures for the Stock Summary report.
@immutable
class StockSummaryData {
  const StockSummaryData({
    required this.totalItems,
    required this.totalQuantity,
    required this.inStock,
    required this.outOfStock,
    required this.lowStock,
  });

  final int totalItems;
  final int totalQuantity;
  final int inStock;
  final int outOfStock;
  final int lowStock;
}
