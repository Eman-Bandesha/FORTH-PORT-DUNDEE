import '../../../core/api/api_client.dart';
import '../../../core/api/api_mappers.dart';
import '../models/movement.dart';
import '../models/movement_filters.dart';
import 'movements_repository.dart';

class MovementsApi {
  const MovementsApi();

  Future<List<Movement>> fetchAll({
    required MovementType type,
    String search = '',
    MovementFilters? filters,
    int pageSize = 200,
  }) async {
    final List<Movement> all = <Movement>[];
    int page = 1;
    while (true) {
      final Map<String, dynamic> data = await apiClient.getJson(
        'movements/',
        query: _queryParams(
          type: type,
          search: search,
          filters: filters,
          page: page,
          pageSize: pageSize,
        ),
      );
      final List<dynamic> results =
          data['results'] as List<dynamic>? ?? <dynamic>[];
      for (final dynamic row in results) {
        if (row is Map<String, dynamic>) {
          all.add(movementFromJson(row));
        }
      }
      final String? next = data['next'] as String?;
      if (next == null || next.isEmpty || results.isEmpty) break;
      page++;
    }
    return all;
  }

  Future<Movement> create({
    required MovementType type,
    required String itemCode,
    required int quantity,
    required String requestedBy,
    String? location,
    String? notes,
    String? reason,
  }) async {
    final Map<String, dynamic> data = await apiClient.postJson(
      'movements/',
      <String, dynamic>{
        'type': movementTypeToApi(type),
        'item_code': itemCode,
        'quantity': quantity,
        'requested_by': requestedBy,
        if (location != null) 'location': location,
        if (notes != null) 'notes': notes,
        if (reason != null) 'reason': reason,
      },
    );
    return movementFromJson(data);
  }

  Future<MovementSummary> fetchSummary() async {
    final Map<String, dynamic> data =
        await apiClient.getJson('movements/summary/');
    return MovementSummary(
      totalIn: (data['total_in'] as num?)?.toInt() ?? 0,
      totalOut: (data['total_out'] as num?)?.toInt() ?? 0,
      transactions: (data['transactions'] as num?)?.toInt() ?? 0,
    );
  }

  Future<int> fetchStockOutToday() async {
    final Map<String, dynamic> data =
        await apiClient.getJson('movements/summary/');
    return (data['stock_out_today'] as num?)?.toInt() ?? 0;
  }

  Future<List<Movement>> fetchRecentStockOut({int limit = 5}) async {
    final dynamic decoded = await apiClient.getDecoded(
      'movements/recent-stock-out/',
      query: <String, String>{'limit': '$limit'},
    );
    if (decoded is! List<dynamic>) return <Movement>[];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(movementFromJson)
        .toList();
  }

  Future<String> fetchNextReference() async {
    final Map<String, dynamic> data =
        await apiClient.getJson('movements/next-reference/');
    return data['reference_no'] as String? ?? 'WO00001';
  }

  Future<List<String>> fetchReasons() async {
    final Map<String, dynamic> data =
        await apiClient.getJson('movements/reasons/');
    return (data['reasons'] as List<dynamic>? ?? <dynamic>[])
        .map((dynamic e) => e.toString())
        .toList();
  }

  Map<String, String> _queryParams({
    required MovementType type,
    required String search,
    MovementFilters? filters,
    required int page,
    required int pageSize,
  }) {
    final MovementFilters f = filters ?? const MovementFilters();
    final Map<String, String> q = <String, String>{
      'page': '$page',
      'page_size': '$pageSize',
      'type': movementTypeToApi(type),
      'sort': movementSortToApi(f.sort),
    };
    if (search.trim().isNotEmpty) q['search'] = search.trim();
    if (f.location != null) q['location'] = f.location!;
    if (f.fromDate != null) {
      q['from_date'] = f.fromDate!.toIso8601String();
    }
    if (f.toDate != null) {
      q['to_date'] = f.toDate!.toIso8601String();
    }
    return q;
  }
}

const MovementsApi movementsApi = MovementsApi();
