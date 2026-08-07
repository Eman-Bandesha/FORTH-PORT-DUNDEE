import '../../items/data/items_repository.dart';
import '../../items/models/item.dart';
import '../../movements/data/movements_repository.dart';
import '../../movements/models/movement.dart';
import '../models/report_models.dart';

/// Derives report aggregations from the in-memory item catalogue and movement
/// ledger. This is dummy/computed data for the frontend; swap the underlying
/// repositories for a backend service later.
class ReportsRepository {
  const ReportsRepository._();

  static List<Item> _items({String? location}) {
    final List<Item> all = ItemsRepository.all;
    if (location == null) return all;
    return all.where((Item i) => i.location == location).toList();
  }

  /// Headline figures for the Stock Summary report, optionally scoped to a
  /// single [location].
  static StockSummaryData summary({String? location}) {
    final List<Item> items = _items(location: location);
    int totalQuantity = 0;
    int inStock = 0;
    int lowStock = 0;
    int outOfStock = 0;
    for (final Item i in items) {
      totalQuantity += i.quantity;
      switch (i.status) {
        case StockStatus.inStock:
          inStock++;
        case StockStatus.lowStock:
          lowStock++;
        case StockStatus.outOfStock:
          outOfStock++;
      }
    }
    return StockSummaryData(
      totalItems: items.length,
      totalQuantity: totalQuantity,
      inStock: inStock,
      outOfStock: outOfStock,
      lowStock: lowStock,
    );
  }

  /// Item count per stock status (for the distribution bar chart).
  static int statusCount(StockStatus status, {String? location}) =>
      _items(location: location).where((Item i) => i.status == status).length;

  /// Total stock quantity grouped by category, highest first.
  static List<NamedQuantity> byCategory({String? location}) {
    final Map<String, int> totals = <String, int>{};
    for (final Item i in _items(location: location)) {
      totals[i.category] = (totals[i.category] ?? 0) + i.quantity;
    }
    return _ranked(totals);
  }

  /// Total stock quantity grouped by location, highest first.
  static List<NamedQuantity> byLocation() {
    final Map<String, int> totals = <String, int>{};
    for (final Item i in ItemsRepository.all) {
      totals[i.location] = (totals[i.location] ?? 0) + i.quantity;
    }
    return _ranked(totals);
  }

  static List<NamedQuantity> _ranked(Map<String, int> totals) {
    final List<NamedQuantity> list = <NamedQuantity>[
      for (final MapEntry<String, int> e in totals.entries)
        NamedQuantity(e.key, e.value),
    ]..sort((NamedQuantity a, NamedQuantity b) {
      final int byQty = b.quantity.compareTo(a.quantity);
      return byQty != 0 ? byQty : a.name.compareTo(b.name);
    });
    return list;
  }

  /// Items at or below their reorder level (low stock + out of stock).
  static List<Item> lowStockItems({String search = ''}) {
    final String q = search.trim().toLowerCase();
    return ItemsRepository.all.where((Item i) {
      final bool needsReorder =
          i.status == StockStatus.lowStock ||
          i.status == StockStatus.outOfStock;
      final bool matches =
          q.isEmpty ||
          i.name.toLowerCase().contains(q) ||
          i.code.toLowerCase().contains(q);
      return needsReorder && matches;
    }).toList()..sort((Item a, Item b) => a.quantity.compareTo(b.quantity));
  }

  /// Total stock-in / stock-out quantities and their net.
  static MovementSummary get movementSummary => MovementsRepository.summary;

  /// Recent movements of [type] (most recent first).
  static List<Movement> recentMovements(MovementType type, {int limit = 6}) =>
      MovementsRepository.recent(type, limit: limit);

  /// Stock-out movements for the Issued Stock report.
  static List<Movement> issuedMovements({String? person}) {
    final List<Movement> out = MovementsRepository.query(
      type: MovementType.stockOut,
    );
    if (person == null) return out;
    return out.where((Movement m) => m.requestedBy == person).toList();
  }

  /// People who have requested/issued stock (for the Issued report filter).
  static List<String> get people =>
      <String>{for (final Movement m in MovementsRepository.query(type: MovementType.stockOut)) m.requestedBy}
          .toList()
        ..sort();

  /// Illustrative 7-day stock movement trend.
  static List<TrendDay> get movementTrend => const <TrendDay>[
    TrendDay(label: '13 May', stockIn: 220, stockOut: 150),
    TrendDay(label: '14 May', stockIn: 260, stockOut: 180),
    TrendDay(label: '15 May', stockIn: 240, stockOut: 210),
    TrendDay(label: '16 May', stockIn: 320, stockOut: 190),
    TrendDay(label: '17 May', stockIn: 300, stockOut: 260),
    TrendDay(label: '18 May', stockIn: 360, stockOut: 240),
    TrendDay(label: '19 May', stockIn: 340, stockOut: 280),
  ];

  static List<String> get itemLocations => ItemsRepository.locations;
}
