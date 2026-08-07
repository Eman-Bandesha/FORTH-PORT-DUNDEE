import 'package:flutter/foundation.dart';

import '../../items/models/stock_movement.dart' show MovementType;

export '../../items/models/stock_movement.dart' show MovementType;

/// A single recorded stock movement (in or out) with full audit details.
@immutable
class Movement {
  const Movement({
    required this.id,
    required this.type,
    required this.itemName,
    required this.itemCode,
    required this.image,
    required this.quantity,
    required this.date,
    required this.referenceNo,
    required this.requestedBy,
    required this.location,
    required this.notes,
    required this.unit,
    required this.stockBefore,
  });

  final String id;
  final MovementType type;
  final String itemName;
  final String itemCode;
  final String image;

  /// Magnitude of the movement (always positive). Direction comes from [type].
  final int quantity;
  final DateTime date;
  final String referenceNo;
  final String requestedBy;
  final String location;
  final String notes;
  final String unit;

  /// Stock level immediately before this movement was applied.
  final int stockBefore;

  bool get isIn => type == MovementType.stockIn;

  /// Signed quantity change (e.g. +25 or -8).
  int get change => isIn ? quantity : -quantity;

  /// Display label with sign, e.g. "+25" / "-8".
  String get changeLabel => '${isIn ? '+' : '-'}$quantity';

  /// Stock level after the movement was applied.
  int get remainingStock => stockBefore + change;

  /// Human-readable timestamp, e.g. "20 May 2024, 10:30 AM".
  String get dateTimeLabel => _formatDateTime(date);

  static const List<String> _months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _formatDateTime(DateTime d) {
    final int hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final String period = d.hour < 12 ? 'AM' : 'PM';
    final String minute = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${_months[d.month - 1]} ${d.year}, '
        '$hour12:$minute $period';
  }

  /// Short date label, e.g. "20 May 2024".
  static String formatDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';
}
