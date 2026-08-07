import 'package:flutter/material.dart';

import '../models/item.dart';

/// A small rounded pill showing an item's [StockStatus].
class StockStatusBadge extends StatelessWidget {
  const StockStatusBadge({super.key, required this.status});

  final StockStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
