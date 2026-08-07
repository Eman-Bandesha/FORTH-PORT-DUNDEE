import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';

/// Direction of a stock movement.
enum MovementType {
  stockIn,
  stockOut;

  String get label =>
      this == MovementType.stockIn ? AppStrings.stockIn : AppStrings.stockOut;

  Color get color => this == MovementType.stockIn
      ? const Color(0xFF1E8E54)
      : const Color(0xFFE1251B);

  IconData get icon => this == MovementType.stockIn
      ? Icons.arrow_downward_rounded
      : Icons.arrow_upward_rounded;
}

/// A single recorded change to an item's stock level.
@immutable
class StockMovement {
  const StockMovement({
    required this.type,
    required this.change,
    required this.dateTime,
    required this.location,
  });

  final MovementType type;

  /// Signed quantity change (e.g. +25 or -10).
  final int change;
  final String dateTime;
  final String location;

  String get changeLabel => '${change > 0 ? '+' : ''}$change';
}
