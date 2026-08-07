import '../../features/items/models/item.dart';
import '../../features/items/models/stock_analytics.dart';
import '../../features/items/models/stock_movement.dart';
import '../../features/movements/models/movement.dart';
import '../../features/movements/models/movement_filters.dart';

StockStatus stockStatusFromApi(String? value) {
  return switch (value) {
    'low_stock' => StockStatus.lowStock,
    'out_of_stock' => StockStatus.outOfStock,
    _ => StockStatus.inStock,
  };
}

String stockStatusToApi(StockStatus status) {
  return switch (status) {
    StockStatus.inStock => 'in_stock',
    StockStatus.lowStock => 'low_stock',
    StockStatus.outOfStock => 'out_of_stock',
  };
}

String itemSortToApi(ItemSort sort) {
  return switch (sort) {
    ItemSort.nameAsc => 'name_asc',
    ItemSort.nameDesc => 'name_desc',
    ItemSort.qtyHighLow => 'qty_high_low',
    ItemSort.qtyLowHigh => 'qty_low_high',
  };
}

String movementSortToApi(MovementSort sort) {
  return switch (sort) {
    MovementSort.newestFirst => 'newest_first',
    MovementSort.oldestFirst => 'oldest_first',
    MovementSort.qtyHighLow => 'qty_high_low',
    MovementSort.qtyLowHigh => 'qty_low_high',
  };
}

MovementType movementTypeFromApi(String? value) {
  return value == 'stock_in' ? MovementType.stockIn : MovementType.stockOut;
}

String movementTypeToApi(MovementType type) {
  return type == MovementType.stockIn ? 'stock_in' : 'stock_out';
}

Item itemFromJson(Map<String, dynamic> json) {
  return Item(
    code: json['code'] as String,
    name: json['name'] as String,
    image: (json['image'] as String?) ?? '',
    status: stockStatusFromApi(json['status'] as String?),
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    category: (json['category'] as String?) ?? '',
    unit: (json['unit'] as String?) ?? 'Each',
    reorderLevel: (json['reorder_level'] as num?)?.toInt() ?? 0,
    location: (json['location'] as String?) ?? '',
    description: (json['description'] as String?) ?? '',
    lastUpdated: (json['last_updated'] as String?) ?? '',
  );
}

Movement movementFromJson(Map<String, dynamic> json) {
  final String dateRaw = json['date'] as String? ?? '';
  DateTime parsed;
  try {
    parsed = DateTime.parse(dateRaw).toLocal();
  } catch (_) {
    parsed = DateTime.now();
  }
  return Movement(
    id: json['id']?.toString() ?? '',
    type: movementTypeFromApi(json['type'] as String?),
    itemName: json['item_name'] as String? ?? '',
    itemCode: json['item_code'] as String? ?? '',
    image: json['image'] as String? ?? '',
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    date: parsed,
    referenceNo: json['reference_no'] as String? ?? '',
    requestedBy: json['requested_by'] as String? ?? '',
    location: json['location'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
    unit: json['unit'] as String? ?? '',
    stockBefore: (json['stock_before'] as num?)?.toInt() ?? 0,
  );
}

StockAnalytics analyticsFromApi(Map<String, dynamic> json, Item item) {
  final List<dynamic> history = json['history'] as List<dynamic>? ?? <dynamic>[];
  final List<StockTrendPoint> trend = <StockTrendPoint>[];
  for (final dynamic row in history) {
    if (row is! Map<String, dynamic>) continue;
    final String date = row['date']?.toString() ?? '';
    final String label = date.length >= 10 ? date.substring(0, 10) : date;
    final String type = row['type'] as String? ?? '';
    final int qty = (row['quantity'] as num?)?.toInt() ?? 0;
    trend.add(
      StockTrendPoint(
        label: label,
        stockIn: type == 'stock_in' ? qty : 0,
        stockOut: type == 'stock_out' ? qty : 0,
        stockLevel: (row['stock_after'] as num?)?.toInt() ?? item.quantity,
      ),
    );
  }
  StockMovement? lastIn;
  StockMovement? lastOut;
  for (final dynamic row in history.reversed) {
    if (row is! Map<String, dynamic>) continue;
    final String type = row['type'] as String? ?? '';
    final int qty = (row['quantity'] as num?)?.toInt() ?? 0;
    final String date = row['date']?.toString() ?? '';
    if (type == 'stock_in' && lastIn == null) {
      lastIn = StockMovement(
        type: MovementType.stockIn,
        change: qty,
        dateTime: date,
        location: item.location,
      );
    }
    if (type == 'stock_out' && lastOut == null) {
      lastOut = StockMovement(
        type: MovementType.stockOut,
        change: -qty,
        dateTime: date,
        location: item.location,
      );
    }
  }
  return StockAnalytics(
    inStock: item.quantity,
    stockInTotal: trend.fold<int>(
      0,
      (int s, StockTrendPoint p) => s + p.stockIn,
    ),
    stockOutTotal: trend.fold<int>(
      0,
      (int s, StockTrendPoint p) => s + p.stockOut,
    ),
    reorderLevel: item.reorderLevel,
    trend: trend.isEmpty
        ? <StockTrendPoint>[
            StockTrendPoint(
              label: 'Now',
              stockIn: 0,
              stockOut: 0,
              stockLevel: item.quantity,
            ),
          ]
        : trend,
    lastIn: lastIn ??
        StockMovement(
          type: MovementType.stockIn,
          change: 0,
          dateTime: '—',
          location: item.location,
        ),
    lastOut: lastOut ??
        StockMovement(
          type: MovementType.stockOut,
          change: 0,
          dateTime: '—',
          location: item.location,
        ),
  );
}
