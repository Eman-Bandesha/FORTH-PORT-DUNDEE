import '../../../core/api/api_client.dart';
import '../../../core/api/api_mappers.dart';
import '../models/item.dart';
import '../models/item_filters.dart';
import '../models/stock_analytics.dart';

class ItemsApi {
  const ItemsApi();

  Future<List<Item>> fetchAll({
    String search = '',
    ItemFilters? filters,
    int pageSize = 500,
  }) async {
    final List<Item> all = <Item>[];
    int page = 1;
    while (true) {
      final Map<String, dynamic> data = await apiClient.getJson(
        'items/',
        query: _queryParams(
          search: search,
          filters: filters,
          page: page,
          pageSize: pageSize,
        ),
      );
      final List<dynamic> results = data['results'] as List<dynamic>? ?? <dynamic>[];
      for (final dynamic row in results) {
        if (row is Map<String, dynamic>) {
          all.add(itemFromJson(row));
        }
      }
      final String? next = data['next'] as String?;
      if (next == null || next.isEmpty || results.isEmpty) break;
      page++;
    }
    return all;
  }

  Future<List<String>> fetchCategories() async {
    final Map<String, dynamic> data =
        await apiClient.getJson('items/meta/categories/');
    return (data['categories'] as List<dynamic>? ?? <dynamic>[])
        .map((dynamic e) => e.toString())
        .toList();
  }

  Future<List<String>> fetchLocations() async {
    final Map<String, dynamic> data =
        await apiClient.getJson('items/meta/locations/');
    return (data['locations'] as List<dynamic>? ?? <dynamic>[])
        .map((dynamic e) => e.toString())
        .toList();
  }

  Future<Item> create(Item item) async {
    final Map<String, dynamic> data = await apiClient.postJson(
      'items/',
      <String, dynamic>{
        'code': item.code,
        'name': item.name,
        'image': item.image,
        'quantity': item.quantity,
        'category': item.category,
        'unit': item.unit,
        'reorder_level': item.reorderLevel,
        'location': item.location,
        'description': item.description,
      },
    );
    return itemFromJson(data);
  }

  Future<Item> update(Item item) async {
    final Map<String, dynamic> data = await apiClient.patchJson(
      'items/${Uri.encodeComponent(item.code)}/',
      <String, dynamic>{
        'name': item.name,
        'image': item.image,
        'quantity': item.quantity,
        'category': item.category,
        'unit': item.unit,
        'reorder_level': item.reorderLevel,
        'location': item.location,
        'description': item.description,
      },
    );
    return itemFromJson(data);
  }

  Future<void> delete(String code) async {
    await apiClient.delete('items/${Uri.encodeComponent(code)}/');
  }

  Future<bool> codeExists(String code) async {
    try {
      await apiClient.getJson('items/${Uri.encodeComponent(code)}/');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<StockAnalytics> analyticsFor(Item item) async {
    final Map<String, dynamic> data = await apiClient.getJson(
      'items/${Uri.encodeComponent(item.code)}/analytics/',
    );
    return analyticsFromApi(data, item);
  }

  Future<String> lastStockOutLabel(String code) async {
    final Map<String, dynamic> data = await apiClient.getJson(
      'items/${Uri.encodeComponent(code)}/last-stock-out/',
    );
    return data['label'] as String? ?? '—';
  }

  Map<String, String> _queryParams({
    required String search,
    ItemFilters? filters,
    required int page,
    required int pageSize,
  }) {
    final ItemFilters f = filters ?? const ItemFilters();
    final Map<String, String> q = <String, String>{
      'page': '$page',
      'page_size': '$pageSize',
      'sort': itemSortToApi(f.sort),
    };
    if (search.trim().isNotEmpty) q['search'] = search.trim();
    if (f.category != null) q['category'] = f.category!;
    if (f.location != null) q['location'] = f.location!;
    if (f.statuses.isNotEmpty) {
      q['status'] = f.statuses.map(stockStatusToApi).join(',');
    }
    return q;
  }
}

const ItemsApi itemsApi = ItemsApi();
