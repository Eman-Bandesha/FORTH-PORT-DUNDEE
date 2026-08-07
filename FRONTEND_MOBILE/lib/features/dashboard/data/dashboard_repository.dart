import '../../../core/api/api_client.dart';
import '../../../core/api/api_mappers.dart';
import '../../items/models/item.dart';
import '../../movements/models/movement.dart';

class DashboardStats {
  const DashboardStats({
    required this.totalItems,
    required this.inStock,
    required this.lowStock,
    required this.outOfStock,
    required this.alertsCount,
    required this.stockOutToday,
    required this.nearExpiry,
    required this.recentStockOut,
    required this.alertItems,
  });

  final int totalItems;
  final int inStock;
  final int lowStock;
  final int outOfStock;
  final int alertsCount;
  final int stockOutToday;
  final int nearExpiry;
  final List<Movement> recentStockOut;
  final List<Item> alertItems;
}

class DashboardRepository {
  DashboardRepository._();

  static DashboardStats? _cached;

  static DashboardStats? get cached => _cached;

  static Future<DashboardStats> refresh() async {
    final Map<String, dynamic> data =
        await apiClient.getJson('dashboard/stats/');
    final List<Movement> recent = (data['recent_stock_out'] as List<dynamic>? ??
            <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(movementFromJson)
        .toList();
    final List<Item> alerts = (data['alert_items'] as List<dynamic>? ??
            <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(itemFromJson)
        .toList();
    _cached = DashboardStats(
      totalItems: (data['total_items'] as num?)?.toInt() ?? 0,
      inStock: (data['in_stock'] as num?)?.toInt() ?? 0,
      lowStock: (data['low_stock'] as num?)?.toInt() ?? 0,
      outOfStock: (data['out_of_stock'] as num?)?.toInt() ?? 0,
      alertsCount: (data['alerts_count'] as num?)?.toInt() ?? 0,
      stockOutToday: (data['stock_out_today'] as num?)?.toInt() ?? 0,
      nearExpiry: (data['near_expiry'] as num?)?.toInt() ?? 0,
      recentStockOut: recent,
      alertItems: alerts,
    );
    return _cached!;
  }

  static void clear() => _cached = null;
}
