import 'package:flutter/foundation.dart';

import 'item.dart';

/// The set of filters/sort applied to the item list.
@immutable
class ItemFilters {
  const ItemFilters({
    this.statuses = const <StockStatus>{},
    this.category,
    this.location,
    this.sort = ItemSort.nameAsc,
  });

  /// Selected stock statuses. Empty means "all".
  final Set<StockStatus> statuses;
  final String? category;
  final String? location;
  final ItemSort sort;

  /// Whether any narrowing filter (not sort) is active.
  bool get isActive =>
      statuses.isNotEmpty || category != null || location != null;

  ItemFilters copyWith({
    Set<StockStatus>? statuses,
    Object? category = _sentinel,
    Object? location = _sentinel,
    ItemSort? sort,
  }) {
    return ItemFilters(
      statuses: statuses ?? this.statuses,
      category: category == _sentinel ? this.category : category as String?,
      location: location == _sentinel ? this.location : location as String?,
      sort: sort ?? this.sort,
    );
  }

  /// Clears the narrowing filters while preserving the current sort.
  ItemFilters cleared() => ItemFilters(sort: sort);

  static const Object _sentinel = Object();
}
