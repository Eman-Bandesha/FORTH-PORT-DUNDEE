import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../movements/data/movements_repository.dart';
import 'models/item.dart';
import 'models/item_filters.dart';
import 'widgets/search_box.dart';
import 'widgets/stock_status_badge.dart';
import '../shell/widgets/tablet_menu_button.dart';

/// Tablet / wide layout for the Items tab: toolbar, data table, pagination.
class ItemsTabletView extends StatelessWidget {
  const ItemsTabletView({
    super.key,
    required this.searchController,
    required this.filters,
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.listViewSelected,
    required this.onSearchChanged,
    required this.onOpenFilters,
    required this.onSortChanged,
    required this.onPageChanged,
    required this.onViewModeChanged,
    required this.onItemTap,
    required this.onRemoveStatus,
    required this.onRemoveCategory,
    required this.onRemoveLocation,
    required this.onClearFilters,
  });

  final TextEditingController searchController;
  final ItemFilters filters;
  final List<Item> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final bool listViewSelected;
  final VoidCallback onSearchChanged;
  final VoidCallback onOpenFilters;
  final ValueChanged<ItemSort> onSortChanged;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<bool> onViewModeChanged;
  final ValueChanged<Item> onItemTap;
  final ValueChanged<StockStatus> onRemoveStatus;
  final VoidCallback onRemoveCategory;
  final VoidCallback onRemoveLocation;
  final VoidCallback onClearFilters;

  int get _totalPages =>
      totalCount == 0 ? 1 : (totalCount / pageSize).ceil();

  int get _rangeStart => totalCount == 0 ? 0 : (page - 1) * pageSize + 1;

  int get _rangeEnd {
    final int end = page * pageSize;
    return end > totalCount ? totalCount : end;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const TabletMenuButton(iconColor: AppColors.navy),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      AppStrings.itemsTitle,
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      AppStrings.itemsSubtitle,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          flex: 3,
                          child: SearchBox(
                            hintText: AppStrings.searchItemsByNameOrCodeHint,
                            controller: searchController,
                            onChanged: (_) => onSearchChanged(),
                            onClear: onSearchChanged,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _ToolbarFilterButton(
                          active: filters.isActive,
                          onTap: onOpenFilters,
                        ),
                        const SizedBox(width: 12),
                        _SortDropdown(
                          sort: filters.sort,
                          onChanged: onSortChanged,
                        ),
                        const SizedBox(width: 12),
                        _ViewToggle(
                          listSelected: listViewSelected,
                          onChanged: onViewModeChanged,
                        ),
                      ],
                    ),
                  ),
                  if (filters.isActive)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: _FilterChipsRow(
                        filters: filters,
                        onRemoveStatus: onRemoveStatus,
                        onRemoveCategory: onRemoveCategory,
                        onRemoveLocation: onRemoveLocation,
                        onClearAll: onClearFilters,
                      ),
                    ),
                  const Divider(height: 1, color: AppColors.border),
                  _TableHeader(listView: listViewSelected),
                  const Divider(height: 1, color: AppColors.border),
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
                        : listViewSelected
                        ? ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, _) => const Divider(
                              height: 1,
                              color: AppColors.border,
                            ),
                            itemBuilder: (BuildContext context, int index) {
                              final Item item = items[index];
                              return _ItemTableRow(
                                item: item,
                                onTap: () => onItemTap(item),
                              );
                            },
                          )
                        : _ItemGrid(
                            items: items,
                            onItemTap: onItemTap,
                          ),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            totalCount == 0
                                ? AppStrings.noItemsFound
                                : '${AppStrings.showingItemsRange} $_rangeStart to $_rangeEnd '
                                      '${AppStrings.ofItemsSuffix} $totalCount '
                                      '${AppStrings.itemsWord}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        _PaginationBar(
                          page: page,
                          totalPages: _totalPages,
                          onPageChanged: onPageChanged,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarFilterButton extends StatelessWidget {
  const _ToolbarFilterButton({required this.active, required this.onTap});

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
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? AppColors.navy : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.filter_list_rounded,
                color: active ? AppColors.white : AppColors.navy,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                AppStrings.filterButtonLabel,
                style: TextStyle(
                  color: active ? AppColors.white : AppColors.navy,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  const _SortDropdown({required this.sort, required this.onChanged});

  final ItemSort sort;
  final ValueChanged<ItemSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ItemSort>(
          value: sort,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textMuted,
          ),
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          items: ItemSort.values
              .map(
                (ItemSort s) => DropdownMenuItem<ItemSort>(
                  value: s,
                  child: Text('${AppStrings.sortPrefix}${s.label}'),
                ),
              )
              .toList(),
          onChanged: (ItemSort? v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({
    required this.listSelected,
    required this.onChanged,
  });

  final bool listSelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _ViewIcon(
            icon: Icons.grid_view_rounded,
            selected: !listSelected,
            tooltip: AppStrings.viewGrid,
            onTap: () => onChanged(false),
          ),
          _ViewIcon(
            icon: Icons.view_list_rounded,
            selected: listSelected,
            tooltip: AppStrings.viewList,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ViewIcon extends StatelessWidget {
  const _ViewIcon({
    required this.icon,
    required this.selected,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 48,
          height: 48,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: selected ? AppColors.link : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: selected ? AppColors.white : AppColors.textMuted,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.listView});

  final bool listView;

  @override
  Widget build(BuildContext context) {
    if (!listView) return const SizedBox.shrink();

    return Container(
      color: const Color(0xFFF3F5F8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: const Row(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Text(AppStrings.itemNameHeader, style: _headerStyle),
          ),
          Expanded(
            flex: 2,
            child: Text(AppStrings.itemCodeHeader, style: _headerStyle),
          ),
          Expanded(
            flex: 2,
            child: Text(AppStrings.categoryLabel, style: _headerStyle),
          ),
          Expanded(
            flex: 2,
            child: Text(AppStrings.currentStockHeader, style: _headerStyle),
          ),
          Expanded(
            flex: 2,
            child: Text(AppStrings.statusHeader, style: _headerStyle),
          ),
          Expanded(
            flex: 2,
            child: Text(AppStrings.lastOutHeader, style: _headerStyle),
          ),
        ],
      ),
    );
  }
}

const TextStyle _headerStyle = TextStyle(
  color: AppColors.navy,
  fontSize: 13,
  fontWeight: FontWeight.w800,
);

class _ItemTableRow extends StatelessWidget {
  const _ItemTableRow({required this.item, required this.onTap});

  final Item item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color stockColor = item.status.foreground;
    final String lastOut =
        MovementsRepository.lastStockOutLabelFor(item.code);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 4,
                child: Row(
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        item.image,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 40,
                          height: 40,
                          color: AppColors.fieldFill,
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  item.code,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  item.category,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${item.quantity} ${item.unit}',
                  style: TextStyle(
                    color: stockColor,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  item.status.label,
                  style: TextStyle(
                    color: stockColor,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  lastOut,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemGrid extends StatelessWidget {
  const _ItemGrid({required this.items, required this.onItemTap});

  final List<Item> items;
  final ValueChanged<Item> onItemTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.35,
      ),
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) {
        final Item item = items[index];
        return Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => onItemTap(item),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        item.image,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: AppColors.fieldFill,
                          child: const Icon(Icons.inventory_2_outlined),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  StockStatusBadge(status: item.status),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({
    required this.filters,
    required this.onRemoveStatus,
    required this.onRemoveCategory,
    required this.onRemoveLocation,
    required this.onClearAll,
  });

  final ItemFilters filters;
  final ValueChanged<StockStatus> onRemoveStatus;
  final VoidCallback onRemoveCategory;
  final VoidCallback onRemoveLocation;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (final StockStatus status in filters.statuses)
                  _Chip(
                    label: status.label,
                    onRemove: () => onRemoveStatus(status),
                  ),
                if (filters.category != null)
                  _Chip(label: filters.category!, onRemove: onRemoveCategory),
                if (filters.location != null)
                  _Chip(label: filters.location!, onRemove: onRemoveLocation),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: onClearAll,
          child: const Text(
            AppStrings.clearAll,
            style: TextStyle(
              color: AppColors.red,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 16,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.onPageChanged,
  });

  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final List<int> pages = _visiblePages(page, totalPages);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _PageIcon(
          icon: Icons.chevron_left_rounded,
          enabled: page > 1,
          onTap: () => onPageChanged(page - 1),
        ),
        for (final int p in pages)
          if (p == -1)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('…', style: TextStyle(color: AppColors.textMuted)),
            )
          else
            _PageNumber(
              number: p,
              selected: p == page,
              onTap: () => onPageChanged(p),
            ),
        _PageIcon(
          icon: Icons.chevron_right_rounded,
          enabled: page < totalPages,
          onTap: () => onPageChanged(page + 1),
        ),
      ],
    );
  }

  static List<int> _visiblePages(int current, int total) {
    if (total <= 5) {
      return List<int>.generate(total, (int i) => i + 1);
    }
    if (current <= 3) return <int>[1, 2, 3, -1, total];
    if (current >= total - 2) {
      return <int>[1, -1, total - 2, total - 1, total];
    }
    return <int>[1, -1, current, -1, total];
  }
}

class _PageNumber extends StatelessWidget {
  const _PageNumber({
    required this.number,
    required this.selected,
    required this.onTap,
  });

  final int number;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: selected ? AppColors.link : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: selected ? null : Border.all(color: AppColors.border),
            ),
            child: Text(
              '$number',
              style: TextStyle(
                color: selected ? AppColors.white : AppColors.navy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PageIcon extends StatelessWidget {
  const _PageIcon({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, color: AppColors.navy),
    );
  }
}
