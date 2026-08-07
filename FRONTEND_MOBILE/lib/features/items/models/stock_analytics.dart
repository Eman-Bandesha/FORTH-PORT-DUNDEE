import 'package:flutter/foundation.dart';

import 'stock_movement.dart';

/// One day's worth of movement figures used by the stock trend chart.
@immutable
class StockTrendPoint {
  const StockTrendPoint({
    required this.label,
    required this.stockIn,
    required this.stockOut,
    required this.stockLevel,
  });

  /// Short axis label, e.g. "13 May".
  final String label;
  final int stockIn;
  final int stockOut;
  final int stockLevel;
}

/// Aggregated analytics for an item's "Stock & History" tab.
@immutable
class StockAnalytics {
  const StockAnalytics({
    required this.inStock,
    required this.stockInTotal,
    required this.stockOutTotal,
    required this.reorderLevel,
    required this.trend,
    required this.lastIn,
    required this.lastOut,
  });

  final int inStock;
  final int stockInTotal;
  final int stockOutTotal;
  final int reorderLevel;
  final List<StockTrendPoint> trend;
  final StockMovement lastIn;
  final StockMovement lastOut;
}
