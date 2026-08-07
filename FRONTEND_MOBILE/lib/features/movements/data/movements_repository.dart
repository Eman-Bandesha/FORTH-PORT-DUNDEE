import '../models/movement.dart';
import '../models/movement_filters.dart';
import 'movements_api.dart';
import 'movements_memory_store.dart';

export 'movements_memory_store.dart' show MovementSummary;

/// Stock movements backed by the REST API, with in-memory mode for tests.
class MovementsRepository {
  const MovementsRepository._();

  static bool memoryMode = false;

  static List<Movement> _apiStockOut = <Movement>[];
  static List<Movement> _apiStockIn = <Movement>[];
  static MovementSummary? _apiSummary;
  static int _stockOutToday = 0;
  static List<String> _apiReasons = <String>[];
  static List<String> _apiLocations = <String>[];
  static String _nextRef = 'WO00001';

  static Future<void> refresh() async {
    if (memoryMode) return;
    _apiStockOut = await movementsApi.fetchAll(type: MovementType.stockOut);
    _apiStockIn = await movementsApi.fetchAll(type: MovementType.stockIn);
    _apiSummary = await movementsApi.fetchSummary();
    _stockOutToday = await movementsApi.fetchStockOutToday();
    _apiReasons = await movementsApi.fetchReasons();
    _nextRef = await movementsApi.fetchNextReference();
    _apiLocations = <String>{
      for (final Movement m in <Movement>[..._apiStockOut, ..._apiStockIn])
        m.location,
    }.toList()
      ..sort();
  }

  static String nextReference() =>
      memoryMode ? MovementsMemoryStore.nextReference() : _nextRef;

  static Future<String> nextReferenceAsync() async {
    if (memoryMode) return MovementsMemoryStore.nextReference();
    _nextRef = await movementsApi.fetchNextReference();
    return _nextRef;
  }

  static Future<Movement> recordMovement({
    required MovementType type,
    required String itemCode,
    required int quantity,
    required String requestedBy,
    String? location,
    String? notes,
    String? reason,
  }) async {
    if (memoryMode) {
      throw UnsupportedError('Use record() in memory mode');
    }
    final Movement created = await movementsApi.create(
      type: type,
      itemCode: itemCode,
      quantity: quantity,
      requestedBy: requestedBy,
      location: location,
      notes: notes,
      reason: reason,
    );
    if (type == MovementType.stockOut) {
      _apiStockOut.insert(0, created);
    } else {
      _apiStockIn.insert(0, created);
    }
    _apiSummary = await movementsApi.fetchSummary();
    _stockOutToday = await movementsApi.fetchStockOutToday();
    _nextRef = await movementsApi.fetchNextReference();
    return created;
  }

  static void record(List<Movement> movements) =>
      MovementsMemoryStore.record(movements);

  static void reset() {
    memoryMode = true;
    _apiStockOut = <Movement>[];
    _apiStockIn = <Movement>[];
    MovementsMemoryStore.reset();
  }

  static void enableApi() {
    memoryMode = false;
    MovementsMemoryStore.reset();
  }

  static List<Movement> query({
    required MovementType type,
    String search = '',
    MovementFilters? filters,
  }) {
    if (memoryMode) {
      return MovementsMemoryStore.query(
        type: type,
        search: search,
        filters: filters,
      );
    }
    final List<Movement> source =
        type == MovementType.stockOut ? _apiStockOut : _apiStockIn;
    return MovementsMemoryStore.query(
      type: type,
      search: search,
      filters: filters,
      source: source,
    );
  }

  static List<Movement> recent(MovementType type, {int limit = 4}) {
    if (memoryMode) return MovementsMemoryStore.recent(type, limit: limit);
    final List<Movement> all = query(type: type);
    return all.take(limit).toList();
  }

  static MovementSummary get summary => memoryMode
      ? MovementsMemoryStore.summary
      : (_apiSummary ??
            const MovementSummary(totalIn: 0, totalOut: 0, transactions: 0));

  static List<String> get locations => memoryMode
      ? MovementsMemoryStore.locations
      : (_apiLocations.isNotEmpty ? _apiLocations : MovementsMemoryStore.locations);

  static List<String> get reasons => memoryMode
      ? MovementsMemoryStore.reasons
      : (_apiReasons.isNotEmpty ? _apiReasons : MovementsMemoryStore.reasons);

  static int get stockOutTodayCount => memoryMode
      ? MovementsMemoryStore.stockOutTodayCount
      : _stockOutToday;

  static String lastStockOutLabelFor(String itemCode) {
    if (memoryMode) {
      return MovementsMemoryStore.lastStockOutLabelFor(itemCode);
    }
    Movement? latest;
    for (final Movement m in _apiStockOut) {
      if (m.itemCode != itemCode) continue;
      if (latest == null || m.date.isAfter(latest.date)) latest = m;
    }
    if (latest == null) return '—';
    return Movement.formatDate(latest.date);
  }

  static Future<List<Movement>> recentStockOutFromApi({int limit = 5}) async {
    if (memoryMode) {
      return MovementsMemoryStore.recent(MovementType.stockOut, limit: limit);
    }
    return movementsApi.fetchRecentStockOut(limit: limit);
  }
}
