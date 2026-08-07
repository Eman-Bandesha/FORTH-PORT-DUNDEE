import '../../../core/constants/app_assets.dart';
import '../models/movement.dart';
import '../models/movement_filters.dart';

/// Aggregated totals for the "Summary (This Month)" panel.
class MovementSummary {
  const MovementSummary({
    required this.totalIn,
    required this.totalOut,
    required this.transactions,
  });

  final int totalIn;
  final int totalOut;
  final int transactions;

  int get net => totalIn - totalOut;
}

/// In-memory movement ledger for widget tests.
class MovementsMemoryStore {
  const MovementsMemoryStore._();

  static final List<Movement> _seed = <Movement>[
    // Stock In
    Movement(
      id: 'm-in-1',
      type: MovementType.stockIn,
      itemName: 'Brush Stiff 130MM',
      itemCode: 'PRN13DGTF',
      image: AppAssets.productBrush,
      quantity: 25,
      date: DateTime(2024, 5, 20, 10, 30),
      referenceNo: 'WO78901',
      requestedBy: 'John Doe',
      location: 'Main Warehouse',
      notes: 'Scheduled restock from supplier.',
      unit: 'Each',
      stockBefore: 10,
    ),
    Movement(
      id: 'm-in-2',
      type: MovementType.stockIn,
      itemName: 'Cable Gland M20 Grey',
      itemCode: 'CGM20GREY',
      image: AppAssets.productGland,
      quantity: 120,
      date: DateTime(2024, 5, 20, 9, 15),
      referenceNo: 'WO78902',
      requestedBy: 'Sarah Lee',
      location: 'Main Warehouse',
      notes: 'Bulk delivery received.',
      unit: 'Each',
      stockBefore: 0,
    ),
    Movement(
      id: 'm-in-3',
      type: MovementType.stockIn,
      itemName: 'Cleaner Degreaser 750ML',
      itemCode: 'CLNR750',
      image: AppAssets.productSprayBottle,
      quantity: 50,
      date: DateTime(2024, 5, 20, 16, 45),
      referenceNo: 'WO78903',
      requestedBy: 'John Doe',
      location: 'Main Warehouse',
      notes: 'Routine replenishment.',
      unit: 'Bottle',
      stockBefore: 0,
    ),
    Movement(
      id: 'm-in-4',
      type: MovementType.stockIn,
      itemName: 'Wire Brush 200MM',
      itemCode: 'WBR200',
      image: AppAssets.productBrush,
      quantity: 40,
      date: DateTime(2024, 5, 19, 14, 20),
      referenceNo: 'WO78904',
      requestedBy: 'Tom Brown',
      location: 'Store A',
      notes: 'New stock allocation.',
      unit: 'Each',
      stockBefore: 6,
    ),
    Movement(
      id: 'm-in-5',
      type: MovementType.stockIn,
      itemName: 'WD-40 Lubricant 400ML',
      itemCode: 'WD400',
      image: AppAssets.productSprayBottle,
      quantity: 7,
      date: DateTime(2024, 5, 18, 15, 20),
      referenceNo: 'WO78905',
      requestedBy: 'Sarah Lee',
      location: 'Main Warehouse',
      notes: 'Top-up order.',
      unit: 'Bottle',
      stockBefore: 7,
    ),
    Movement(
      id: 'm-in-6',
      type: MovementType.stockIn,
      itemName: 'Gloves Nitrile Large (Pair)',
      itemCode: 'GNLRG',
      image: AppAssets.productGloves,
      quantity: 30,
      date: DateTime(2024, 5, 18, 11, 10),
      referenceNo: 'WO78906',
      requestedBy: 'John Doe',
      location: 'Store B',
      notes: 'PPE restock.',
      unit: 'Pair',
      stockBefore: 0,
    ),
    // Stock Out
    Movement(
      id: 'm-out-1',
      type: MovementType.stockOut,
      itemName: 'Cable Tie 300MM X 4.8MM',
      itemCode: 'CT300X48',
      image: AppAssets.productCableTies,
      quantity: 10,
      date: DateTime(2024, 5, 20, 9, 15),
      referenceNo: 'WO78910',
      requestedBy: 'Tom Brown',
      location: 'Store A',
      notes: 'Issued to site team.',
      unit: 'Pack',
      stockBefore: 60,
    ),
    Movement(
      id: 'm-out-2',
      type: MovementType.stockOut,
      itemName: 'Cleaner Degreaser 750ML',
      itemCode: 'CLNR750',
      image: AppAssets.productSprayBottle,
      quantity: 5,
      date: DateTime(2024, 5, 19, 13, 40),
      referenceNo: 'WO78911',
      requestedBy: 'Sarah Lee',
      location: 'Main Warehouse',
      notes: 'Workshop usage.',
      unit: 'Bottle',
      stockBefore: 55,
    ),
    Movement(
      id: 'm-out-3',
      type: MovementType.stockOut,
      itemName: 'Gloves Nitrile Large (Pair)',
      itemCode: 'GNLRG',
      image: AppAssets.productGloves,
      quantity: 20,
      date: DateTime(2024, 5, 18, 16, 15),
      referenceNo: 'WO78912',
      requestedBy: 'John Doe',
      location: 'Store B',
      notes: 'Issued to maintenance crew.',
      unit: 'Pair',
      stockBefore: 30,
    ),
    Movement(
      id: 'm-out-4',
      type: MovementType.stockOut,
      itemName: 'Brush Stiff 130MM',
      itemCode: 'PRN13DGTF',
      image: AppAssets.productBrush,
      quantity: 8,
      date: DateTime(2024, 5, 18, 14, 10),
      referenceNo: 'WO78907',
      requestedBy: 'John Doe',
      location: 'Main Warehouse',
      notes: 'Routine maintenance.',
      unit: 'Each',
      stockBefore: 35,
    ),
    Movement(
      id: 'm-out-5',
      type: MovementType.stockOut,
      itemName: 'Duct Tape 18MM X 20M',
      itemCode: 'DT1820',
      image: AppAssets.productCableTies,
      quantity: 3,
      date: DateTime(2024, 5, 18, 10, 25),
      referenceNo: 'WO78913',
      requestedBy: 'Tom Brown',
      location: 'Workshop A',
      notes: 'General repairs.',
      unit: 'Roll',
      stockBefore: 12,
    ),
  ];

  /// The live, mutable ledger (seeded from [_seed]).
  static final List<Movement> _movements = <Movement>[..._seed];

  static int _refCounter = 76906;

  /// Generates the next dummy reference number, e.g. "WO76907".
  static String nextReference() => 'WO${++_refCounter}';

  /// Appends recorded [movements] to the ledger.
  static void record(List<Movement> movements) => _movements.addAll(movements);

  /// Restores the seed data (used to keep tests isolated).
  static void reset() {
    _movements
      ..clear()
      ..addAll(_seed);
    _refCounter = 76906;
  }

  /// Returns movements of [type] matching [search] and [filters], ordered by
  /// the chosen sort.
  static List<Movement> query({
    required MovementType type,
    String search = '',
    MovementFilters? filters,
    List<Movement>? source,
  }) {
    final List<Movement> ledger = source ?? _movements;
    final MovementFilters f = filters ?? const MovementFilters();
    final String q = search.trim().toLowerCase();

    final List<Movement> result = ledger.where((Movement m) {
      if (m.type != type) return false;
      final bool matchesQuery =
          q.isEmpty ||
          m.itemName.toLowerCase().contains(q) ||
          m.itemCode.toLowerCase().contains(q);
      final bool matchesLocation =
          f.location == null || m.location == f.location;
      final bool matchesFrom =
          f.fromDate == null || !m.date.isBefore(_dayStart(f.fromDate!));
      final bool matchesTo =
          f.toDate == null || !m.date.isAfter(_dayEnd(f.toDate!));
      return matchesQuery && matchesLocation && matchesFrom && matchesTo;
    }).toList();

    result.sort((Movement a, Movement b) {
      return switch (f.sort) {
        MovementSort.newestFirst => b.date.compareTo(a.date),
        MovementSort.oldestFirst => a.date.compareTo(b.date),
        MovementSort.qtyHighLow => b.quantity.compareTo(a.quantity),
        MovementSort.qtyLowHigh => a.quantity.compareTo(b.quantity),
      };
    });

    return result;
  }

  /// The most recent [limit] movements of [type] (for the overview panel).
  static List<Movement> recent(MovementType type, {int limit = 4}) {
    final List<Movement> all = query(type: type);
    return all.take(limit).toList();
  }

  static MovementSummary get summary {
    int totalIn = 0;
    int totalOut = 0;
    for (final Movement m in _movements) {
      if (m.isIn) {
        totalIn += m.quantity;
      } else {
        totalOut += m.quantity;
      }
    }
    return MovementSummary(
      totalIn: totalIn,
      totalOut: totalOut,
      transactions: _movements.length,
    );
  }

  static List<String> get locations =>
      <String>{for (final Movement m in _movements) m.location}.toList()
        ..sort();

  /// Reasons offered when issuing (stock-out) inventory.
  static const List<String> reasons = <String>[
    'Sale / Order',
    'Internal Use',
    'Damaged',
    'Wastage',
    'Returned to Supplier',
    'Transfer',
  ];

  static DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _dayEnd(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59);

  /// Stock-out movements on [day] (calendar day).
  static int stockOutCountOn(DateTime day) {
    final DateTime start = _dayStart(day);
    final DateTime end = _dayEnd(day);
    return _movements
        .where(
          (Movement m) =>
              m.type == MovementType.stockOut &&
              !m.date.isBefore(start) &&
              !m.date.isAfter(end),
        )
        .length;
  }

  /// Count for the "Stock Out Today" dashboard tile (today, or demo day).
  static int get stockOutTodayCount {
    final int today = stockOutCountOn(DateTime.now());
    if (today > 0) return today;
    return stockOutCountOn(DateTime(2024, 5, 20));
  }

  /// Most recent stock-out date label for an item code, or "—" if none.
  static String lastStockOutLabelFor(String itemCode) {
    Movement? latest;
    for (final Movement m in _movements) {
      if (m.type != MovementType.stockOut || m.itemCode != itemCode) continue;
      if (latest == null || m.date.isAfter(latest.date)) latest = m;
    }
    if (latest == null) return '—';
    return Movement.formatDate(latest.date);
  }
}
