import '../../../core/constants/app_assets.dart';
import '../models/item.dart';
import '../models/item_filters.dart';
import '../models/stock_analytics.dart';
import '../models/stock_movement.dart';

/// In-memory catalogue used for widget tests and offline demos.
class ItemsMemoryStore {
  const ItemsMemoryStore();

  static const List<Item> _seed = <Item>[
    Item(
      code: 'PRN13DGTF',
      name: 'Brush Stiff 130MM',
      image: AppAssets.productBrush,
      status: StockStatus.inStock,
      quantity: 35,
      category: 'Tools',
      unit: 'Each',
      reorderLevel: 10,
      location: 'Main Warehouse',
      description: 'Stiff bristle brush 130mm wide.',
      lastUpdated: '20 May 2024, 10:30 AM',
    ),
    Item(
      code: 'CGM20GREY',
      name: 'Cable Gland M20 Grey',
      image: AppAssets.productGland,
      status: StockStatus.inStock,
      quantity: 120,
      category: 'Electrical',
      unit: 'Each',
      reorderLevel: 30,
      location: 'Main Warehouse',
      description: 'Grey nylon cable gland, M20 thread, IP68 rated.',
      lastUpdated: '18 May 2024, 09:05 AM',
    ),
    Item(
      code: 'CT300X48',
      name: 'Cable Tie 300MM X 4.8MM',
      image: AppAssets.productCableTies,
      status: StockStatus.lowStock,
      quantity: 50,
      category: 'Electrical',
      unit: 'Pack',
      reorderLevel: 60,
      location: 'Store A',
      description: 'Black UV-resistant nylon cable ties, pack of 100.',
      lastUpdated: '15 May 2024, 02:45 PM',
    ),
    Item(
      code: 'CLNR750',
      name: 'Cleaner Degreaser 750ML',
      image: AppAssets.productSprayBottle,
      status: StockStatus.inStock,
      quantity: 50,
      category: 'Cleaning',
      unit: 'Bottle',
      reorderLevel: 15,
      location: 'Main Warehouse',
      description: 'Heavy-duty industrial cleaner degreaser, 750ml spray.',
      lastUpdated: '12 May 2024, 11:20 AM',
    ),
    Item(
      code: 'GNLRG',
      name: 'Gloves Nitrile Large (Pair)',
      image: AppAssets.productGloves,
      status: StockStatus.outOfStock,
      quantity: 0,
      category: 'PPE',
      unit: 'Pair',
      reorderLevel: 25,
      location: 'Store B',
      description: 'Blue nitrile gloves, large, chemical resistant.',
      lastUpdated: '10 May 2024, 04:10 PM',
    ),
    Item(
      code: 'PRN5DTF',
      name: 'Brush Stiff 50MM',
      image: AppAssets.productBrush,
      status: StockStatus.inStock,
      quantity: 36,
      category: 'Tools',
      unit: 'Each',
      reorderLevel: 10,
      location: 'Main Warehouse',
      description: 'Stiff bristle brush 50mm wide.',
      lastUpdated: '20 May 2024, 10:30 AM',
    ),
    Item(
      code: 'PRN7SOFT',
      name: 'Brush Soft 75MM',
      image: AppAssets.productBrush,
      status: StockStatus.lowStock,
      quantity: 8,
      category: 'Tools',
      unit: 'Each',
      reorderLevel: 12,
      location: 'Store A',
      description: 'Soft bristle brush 75mm wide.',
      lastUpdated: '19 May 2024, 03:15 PM',
    ),
    Item(
      code: 'WBR200',
      name: 'Wire Brush 200MM',
      image: AppAssets.productBrush,
      status: StockStatus.inStock,
      quantity: 6,
      category: 'Tools',
      unit: 'Each',
      reorderLevel: 5,
      location: 'Main Warehouse',
      description: 'Steel wire brush 200mm for rust removal.',
      lastUpdated: '17 May 2024, 08:50 AM',
    ),
    Item(
      code: 'PBS3PCS',
      name: 'Paint Brush Set (3 PCS)',
      image: AppAssets.productBrush,
      status: StockStatus.inStock,
      quantity: 22,
      category: 'Tools',
      unit: 'Set',
      reorderLevel: 8,
      location: 'Store B',
      description: 'Assorted paint brush set, three pieces.',
      lastUpdated: '16 May 2024, 01:00 PM',
    ),
    Item(
      code: 'WD400',
      name: 'WD-40 Lubricant 400ML',
      image: AppAssets.productSprayBottle,
      status: StockStatus.lowStock,
      quantity: 7,
      category: 'Cleaning',
      unit: 'Bottle',
      reorderLevel: 12,
      location: 'Main Warehouse',
      description: 'Multi-use lubricant and penetrant, 400ml.',
      lastUpdated: '14 May 2024, 05:30 PM',
    ),
  ];

  /// The live, mutable catalogue (seeded from [_seed]).
  static final List<Item> _items = <Item>[..._seed];

  /// Current catalogue snapshot.
  static List<Item> get all => List<Item>.unmodifiable(_items);

  /// Adds a brand-new [item] to the top of the catalogue.
  static void add(Item item) => _items.insert(0, item);

  /// True if an item already uses [code] (case-insensitive).
  static bool codeExists(String code) {
    final String c = code.trim().toLowerCase();
    return _items.any((Item i) => i.code.toLowerCase() == c);
  }

  /// Derives a stock status from the quantity relative to the reorder level.
  static StockStatus statusFor({
    required int quantity,
    required int reorderLevel,
  }) {
    if (quantity <= 0) return StockStatus.outOfStock;
    if (quantity <= reorderLevel) return StockStatus.lowStock;
    return StockStatus.inStock;
  }

  /// Removes the item with [code]. Returns true if something was removed.
  static bool delete(String code) {
    final int before = _items.length;
    _items.removeWhere((Item i) => i.code == code);
    return _items.length != before;
  }

  /// Replaces the item that shares [updated]'s code, if present.
  static void update(Item updated) {
    final int index = _items.indexWhere((Item i) => i.code == updated.code);
    if (index != -1) _items[index] = updated;
  }

  /// Restores the seed data (used to keep tests isolated).
  static void reset() {
    _items
      ..clear()
      ..addAll(_seed);
  }

  /// Dummy stock-movement history for an item.
  static List<StockMovement> historyFor(Item item) {
    return <StockMovement>[
      StockMovement(
        type: MovementType.stockIn,
        change: 25,
        dateTime: '20 May 2024, 10:30 AM',
        location: item.location,
      ),
      const StockMovement(
        type: MovementType.stockOut,
        change: -10,
        dateTime: '20 May 2024, 09:15 AM',
        location: 'Workshop A',
      ),
      StockMovement(
        type: MovementType.stockIn,
        change: 20,
        dateTime: '19 May 2024, 04:45 PM',
        location: item.location,
      ),
    ];
  }

  /// Dummy aggregated analytics for an item's "Stock & History" tab.
  ///
  /// Totals are derived from the item's reorder level so each item shows
  /// plausible, distinct figures; the 7-day trend is illustrative sample data.
  static StockAnalytics analyticsFor(Item item) {
    const List<String> days = <String>[
      '13 May',
      '14 May',
      '15 May',
      '16 May',
      '17 May',
      '18 May',
      '19 May',
    ];
    const List<int> ins = <int>[22, 25, 24, 26, 21, 28, 24];
    const List<int> outs = <int>[15, 14, 16, 13, 11, 17, 14];
    const List<int> levels = <int>[55, 38, 40, 45, 40, 48, 40];

    final List<StockTrendPoint> trend = <StockTrendPoint>[
      for (int i = 0; i < days.length; i++)
        StockTrendPoint(
          label: days[i],
          stockIn: ins[i],
          stockOut: outs[i],
          stockLevel: levels[i],
        ),
    ];

    return StockAnalytics(
      inStock: item.quantity,
      stockInTotal: item.reorderLevel * 12,
      stockOutTotal: item.reorderLevel * 8 + 5,
      reorderLevel: item.reorderLevel,
      trend: trend,
      lastIn: const StockMovement(
        type: MovementType.stockIn,
        change: 25,
        dateTime: '19 May 2024, 02:10 PM',
        location: 'Main Warehouse',
      ),
      lastOut: const StockMovement(
        type: MovementType.stockOut,
        change: -10,
        dateTime: '18 May 2024, 11:45 AM',
        location: 'Workshop A',
      ),
    );
  }

  /// Returns items matching [search] and [filters], ordered by the chosen sort.
  static List<Item> query({
    String search = '',
    ItemFilters? filters,
    List<Item>? source,
  }) {
    final List<Item> catalogue = source ?? _items;
    final ItemFilters f = filters ?? const ItemFilters();
    final String q = search.trim().toLowerCase();

    final List<Item> result = catalogue.where((Item item) {
      final bool matchesQuery =
          q.isEmpty ||
          item.name.toLowerCase().contains(q) ||
          item.code.toLowerCase().contains(q);
      final bool matchesStatus =
          f.statuses.isEmpty || f.statuses.contains(item.status);
      final bool matchesCategory =
          f.category == null || item.category == f.category;
      final bool matchesLocation =
          f.location == null || item.location == f.location;
      return matchesQuery &&
          matchesStatus &&
          matchesCategory &&
          matchesLocation;
    }).toList();

    result.sort((Item a, Item b) {
      return switch (f.sort) {
        ItemSort.nameAsc => a.name.compareTo(b.name),
        ItemSort.nameDesc => b.name.compareTo(a.name),
        ItemSort.qtyHighLow => b.quantity.compareTo(a.quantity),
        ItemSort.qtyLowHigh => a.quantity.compareTo(b.quantity),
      };
    });

    return result;
  }

  static List<String> get categories =>
      <String>{for (final Item i in _items) i.category}.toList()..sort();

  static List<String> get locations =>
      <String>{for (final Item i in _items) i.location}.toList()..sort();
}
