import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';

/// Stock availability of an item.
enum StockStatus {
  inStock,
  lowStock,
  outOfStock;

  String get label => switch (this) {
    StockStatus.inStock => AppStrings.inStock,
    StockStatus.lowStock => AppStrings.lowStock,
    StockStatus.outOfStock => AppStrings.outOfStock,
  };

  /// Foreground (text/icon) colour for the status badge.
  Color get foreground => switch (this) {
    StockStatus.inStock => const Color(0xFF1E8E54),
    StockStatus.lowStock => const Color(0xFFC9821B),
    StockStatus.outOfStock => AppColors.red,
  };

  /// Background fill for the status badge.
  Color get background => switch (this) {
    StockStatus.inStock => const Color(0xFFE6F6EC),
    StockStatus.lowStock => const Color(0xFFFCF1DE),
    StockStatus.outOfStock => const Color(0xFFFBE7E6),
  };
}

/// How a list of items is ordered.
enum ItemSort {
  nameAsc,
  nameDesc,
  qtyHighLow,
  qtyLowHigh;

  String get label => switch (this) {
    ItemSort.nameAsc => AppStrings.sortNameAsc,
    ItemSort.nameDesc => AppStrings.sortNameDesc,
    ItemSort.qtyHighLow => AppStrings.sortQtyHighLow,
    ItemSort.qtyLowHigh => AppStrings.sortQtyLowHigh,
  };
}

/// An inventory item.
@immutable
class Item {
  const Item({
    required this.code,
    required this.name,
    required this.image,
    required this.status,
    required this.quantity,
    required this.category,
    required this.unit,
    required this.reorderLevel,
    required this.location,
    required this.description,
    required this.lastUpdated,
  });

  final String code;
  final String name;
  final String image;
  final StockStatus status;
  final int quantity;
  final String category;
  final String unit;
  final int reorderLevel;
  final String location;
  final String description;
  final String lastUpdated;

  Item copyWith({
    String? code,
    String? name,
    String? image,
    StockStatus? status,
    int? quantity,
    String? category,
    String? unit,
    int? reorderLevel,
    String? location,
    String? description,
    String? lastUpdated,
  }) {
    return Item(
      code: code ?? this.code,
      name: name ?? this.name,
      image: image ?? this.image,
      status: status ?? this.status,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      location: location ?? this.location,
      description: description ?? this.description,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
