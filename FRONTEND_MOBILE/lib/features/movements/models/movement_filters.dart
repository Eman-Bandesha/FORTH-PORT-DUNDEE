import 'package:flutter/foundation.dart';

import '../../../core/constants/app_strings.dart';
import 'movement.dart';

/// How a list of movements is ordered.
enum MovementSort {
  newestFirst,
  oldestFirst,
  qtyHighLow,
  qtyLowHigh;

  String get label => switch (this) {
    MovementSort.newestFirst => AppStrings.sortNewestFirst,
    MovementSort.oldestFirst => AppStrings.sortOldestFirst,
    MovementSort.qtyHighLow => AppStrings.sortQtyHighLow,
    MovementSort.qtyLowHigh => AppStrings.sortQtyLowHigh,
  };
}

/// Filters applied to the movements list.
@immutable
class MovementFilters {
  const MovementFilters({
    this.type,
    this.fromDate,
    this.toDate,
    this.location,
    this.sort = MovementSort.newestFirst,
  });

  /// Restricts to a direction. `null` means both.
  final MovementType? type;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? location;
  final MovementSort sort;

  bool get isActive =>
      type != null ||
      fromDate != null ||
      toDate != null ||
      location != null;

  MovementFilters copyWith({
    Object? type = _sentinel,
    Object? fromDate = _sentinel,
    Object? toDate = _sentinel,
    Object? location = _sentinel,
    MovementSort? sort,
  }) {
    return MovementFilters(
      type: type == _sentinel ? this.type : type as MovementType?,
      fromDate: fromDate == _sentinel ? this.fromDate : fromDate as DateTime?,
      toDate: toDate == _sentinel ? this.toDate : toDate as DateTime?,
      location: location == _sentinel ? this.location : location as String?,
      sort: sort ?? this.sort,
    );
  }

  static const Object _sentinel = Object();
}
