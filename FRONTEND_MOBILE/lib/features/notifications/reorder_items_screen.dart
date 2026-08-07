import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../items/data/items_repository.dart';
import '../items/models/item.dart';
import '../items/models/item_filters.dart';
import '../items/widgets/search_box.dart';
import '../items/widgets/stock_status_badge.dart';
import '../movements/models/movement.dart';
import '../movements/movement_form_screen.dart';

/// Lists the items in a given [StockStatus] (out of stock / low stock) with
/// their reorder figures — no pricing. Tapping an item opens the Stock In form
/// pre-loaded with that item so the user can record incoming stock.
class ReorderItemsScreen extends StatefulWidget {
  const ReorderItemsScreen({super.key, required this.status});

  final StockStatus status;

  @override
  State<ReorderItemsScreen> createState() => _ReorderItemsScreenState();
}

/// How the reorder list is ordered.
enum ReorderSort {
  priority,
  category,
  nameAsc,
  unitsToOrder;

  String get label => switch (this) {
    ReorderSort.priority => AppStrings.sortPriorityLabel,
    ReorderSort.category => AppStrings.categoryLabel,
    ReorderSort.nameAsc => AppStrings.sortNameAsc,
    ReorderSort.unitsToOrder => AppStrings.unitsToOrderLabel,
  };
}

/// Units that should be reordered to clear an item's shortfall.
int reorderUnitsFor(Item item) {
  final int gap = item.reorderLevel - item.quantity;
  return gap > 0 ? gap : item.reorderLevel;
}

class _ReorderItemsScreenState extends State<ReorderItemsScreen> {
  final TextEditingController _search = TextEditingController();
  ReorderSort _sort = ReorderSort.priority;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _title => widget.status == StockStatus.outOfStock
      ? AppStrings.outOfStockItemsTitle
      : AppStrings.lowStockItemsTitle;

  String get _searchHint => widget.status == StockStatus.outOfStock
      ? AppStrings.searchOutOfStockHint
      : AppStrings.searchLowStockHint;

  List<Item> _sorted(List<Item> items) {
    final List<Item> list = List<Item>.of(items);
    switch (_sort) {
      case ReorderSort.priority:
        // Lowest stock first (most urgent), then by largest shortfall.
        list.sort((Item a, Item b) {
          final int byStock = a.quantity.compareTo(b.quantity);
          if (byStock != 0) return byStock;
          return reorderUnitsFor(b).compareTo(reorderUnitsFor(a));
        });
      case ReorderSort.category:
        list.sort((Item a, Item b) {
          final int byCat = a.category.toLowerCase().compareTo(
            b.category.toLowerCase(),
          );
          return byCat != 0 ? byCat : a.name.compareTo(b.name);
        });
      case ReorderSort.nameAsc:
        list.sort(
          (Item a, Item b) =>
              a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case ReorderSort.unitsToOrder:
        list.sort(
          (Item a, Item b) =>
              reorderUnitsFor(b).compareTo(reorderUnitsFor(a)),
        );
    }
    return list;
  }

  Future<void> _openSort() async {
    final ReorderSort? picked = await showModalBottomSheet<ReorderSort>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SortSheet(current: _sort),
    );
    if (picked != null && mounted) setState(() => _sort = picked);
  }

  Future<void> _openStockIn(Item item) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            MovementFormScreen(type: MovementType.stockIn, item: item),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final List<Item> items = _sorted(
      ItemsRepository.query(
        search: _search.text,
        filters: ItemFilters(statuses: <StockStatus>{widget.status}),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: Text(_title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: SearchBox(
                      hintText: _searchHint,
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      onClear: () => setState(() => _search.clear()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _SortButton(
                    active: _sort != ReorderSort.priority,
                    onTap: _openSort,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    '${items.length}${AppStrings.itemsCountSuffix}',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${AppStrings.sortPrefix}${_sort.label}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Text(
                        AppStrings.noItemsFound,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 15,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: items.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Item item = items[index];
                        return _ReorderCard(
                          item: item,
                          onTap: () => _openStockIn(item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Square icon button that opens the sort options.
class _SortButton extends StatelessWidget {
  const _SortButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.navy : AppColors.fieldFill,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? AppColors.navy : AppColors.border),
          ),
          child: Icon(
            Icons.tune_rounded,
            color: active ? AppColors.white : AppColors.navy,
            size: 22,
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet listing the available sort options.
class _SortSheet extends StatelessWidget {
  const _SortSheet({required this.current});

  final ReorderSort current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              AppStrings.sortByLabel,
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            for (final ReorderSort option in ReorderSort.values)
              InkWell(
                onTap: () => Navigator.of(context).pop(option),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        option == current
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: option == current
                            ? AppColors.navy
                            : AppColors.textMuted,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        option.label,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReorderCard extends StatelessWidget {
  const _ReorderCard({required this.item, required this.onTap});

  final Item item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0A0A2240),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        item.image,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 52,
                          height: 52,
                          color: AppColors.fieldFill,
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            color: AppColors.textMuted,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.code,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StockStatusBadge(status: item.status),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _Metric(
                        label: AppStrings.reorderLevelLabel,
                        value: '${item.reorderLevel}',
                        valueColor: AppColors.navy,
                      ),
                    ),
                    Expanded(
                      child: _Metric(
                        label: AppStrings.unitsToOrderLabel,
                        value: '${reorderUnitsFor(item)}',
                        valueColor: AppColors.red,
                        alignEnd: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.valueColor,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignEnd
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
