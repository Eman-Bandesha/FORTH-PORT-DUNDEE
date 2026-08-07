import '../models/item.dart';
import '../models/item_filters.dart';
import '../models/stock_analytics.dart';
import '../models/stock_movement.dart';
import 'items_api.dart';
import 'items_memory_store.dart';

/// Inventory catalogue backed by the REST API, with an in-memory mode for tests.
class ItemsRepository {
  const ItemsRepository();

  static bool memoryMode = false;

  static List<Item> _apiCache = <Item>[];
  static List<String> _apiCategories = <String>[];
  static List<String> _apiLocations = <String>[];

  static String _lastSearch = '';
  static ItemFilters? _lastFilters;

  static bool get isMemoryMode => memoryMode;

  /// Loads or reloads the catalogue from `GET /items/` (all pages).
  static Future<void> refresh({
    String search = '',
    ItemFilters? filters,
  }) async {
    if (memoryMode) return;
    _lastSearch = search;
    _lastFilters = filters;
    _apiCache = await itemsApi.fetchAll(search: search, filters: filters);
    _apiCategories = await itemsApi.fetchCategories();
    _apiLocations = await itemsApi.fetchLocations();
  }

  static List<Item> get all =>
      memoryMode ? ItemsMemoryStore.all : List<Item>.unmodifiable(_apiCache);

  static List<Item> query({String search = '', ItemFilters? filters}) {
    if (memoryMode) {
      return ItemsMemoryStore.query(search: search, filters: filters);
    }
    return ItemsMemoryStore.query(
      search: search,
      filters: filters,
      source: _apiCache,
    );
  }

  static Future<void> add(Item item) async {
    if (memoryMode) {
      ItemsMemoryStore.add(item);
      return;
    }
    final Item created = await itemsApi.create(item);
    _apiCache.insert(0, created);
  }

  static Future<bool> codeExists(String code) async {
    if (memoryMode) return ItemsMemoryStore.codeExists(code);
    return itemsApi.codeExists(code);
  }

  static StockStatus statusFor({
    required int quantity,
    required int reorderLevel,
  }) =>
      ItemsMemoryStore.statusFor(
        quantity: quantity,
        reorderLevel: reorderLevel,
      );

  static Future<bool> delete(String code) async {
    if (memoryMode) return ItemsMemoryStore.delete(code);
    await itemsApi.delete(code);
    _apiCache.removeWhere((Item i) => i.code == code);
    return true;
  }

  static Future<void> update(Item updated) async {
    if (memoryMode) {
      ItemsMemoryStore.update(updated);
      return;
    }
    final Item saved = await itemsApi.update(updated);
    final int index = _apiCache.indexWhere((Item i) => i.code == saved.code);
    if (index != -1) {
      _apiCache[index] = saved;
    }
  }

  static void reset() {
    memoryMode = true;
    _apiCache = <Item>[];
    ItemsMemoryStore.reset();
  }

  static void enableApi() {
    memoryMode = false;
    ItemsMemoryStore.reset();
  }

  static List<StockMovement> historyFor(Item item) =>
      ItemsMemoryStore.historyFor(item);

  static Future<StockAnalytics> analyticsFor(Item item) async {
    if (memoryMode) return ItemsMemoryStore.analyticsFor(item);
    return itemsApi.analyticsFor(item);
  }

  static Future<String> lastStockOutLabelFor(String itemCode) async {
    if (memoryMode) return '—';
    return itemsApi.lastStockOutLabel(itemCode);
  }

  static List<String> get categories => memoryMode
      ? ItemsMemoryStore.categories
      : (_apiCategories.isNotEmpty
            ? _apiCategories
            : <String>{for (final Item i in _apiCache) i.category}.toList()
              ..sort());

  static List<String> get locations => memoryMode
      ? ItemsMemoryStore.locations
      : (_apiLocations.isNotEmpty
            ? _apiLocations
            : <String>{for (final Item i in _apiCache) i.location}.toList()
              ..sort());
}
