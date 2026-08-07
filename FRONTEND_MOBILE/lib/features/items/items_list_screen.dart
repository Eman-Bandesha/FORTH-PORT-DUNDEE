import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/layout/app_breakpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_snackbar.dart';
import 'data/items_repository.dart';
import 'filters_screen.dart';
import 'item_details_screen.dart';
import 'items_tablet_view.dart';
import 'models/item.dart';
import 'models/item_filters.dart';
import 'search_items_screen.dart';
import 'widgets/item_card.dart';
import 'widgets/search_box.dart';

/// The Items tab: searchable, filterable list of inventory items.
///
/// On phone, shows cards with a tap-through search box. On tablet (≥768px),
/// shows the data-table layout with live search, sort, filters, and pagination.
class ItemsListScreen extends StatefulWidget {
  const ItemsListScreen({super.key});

  @override
  State<ItemsListScreen> createState() => _ItemsListScreenState();
}

class _ItemsListScreenState extends State<ItemsListScreen> {
  static const int _tabletPageSize = 5;

  ItemFilters _filters = const ItemFilters();
  final TextEditingController _tabletSearch = TextEditingController();
  int _page = 1;
  bool _listView = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (!ItemsRepository.isMemoryMode) {
      unawaited(_reloadCatalog());
    }
  }

  Future<void> _reloadCatalog() async {
    setState(() => _loading = true);
    try {
      await ItemsRepository.refresh(
        search: _tabletSearch.text,
        filters: _filters,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tabletSearch.dispose();
    super.dispose();
  }

  List<Item> _queryAll() => ItemsRepository.query(
    search: _tabletSearch.text,
    filters: _filters,
  );

  Future<void> _openFilters() async {
    final ItemFilters? result = await Navigator.of(context).push(
      MaterialPageRoute<ItemFilters>(
        builder: (_) => FiltersScreen(initial: _filters),
      ),
    );
    if (result != null) {
      setState(() {
        _filters = result;
        _page = 1;
      });
      if (!ItemsRepository.isMemoryMode) unawaited(_reloadCatalog());
    }
  }

  Future<void> _openSearch() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SearchItemsScreen()));
    if (mounted) setState(() {});
  }

  Future<void> _openDetails(Item item) async {
    final ItemDetailsResult? result = await Navigator.of(context).push(
      MaterialPageRoute<ItemDetailsResult>(
        builder: (_) => ItemDetailsScreen(item: item),
      ),
    );
    if (!mounted) return;
    setState(() {
      final int total = _queryAll().length;
      final int pages =
          total == 0 ? 1 : (total / _tabletPageSize).ceil();
      if (_page > pages) _page = pages;
    });
  }

  void _removeStatus(StockStatus status) {
    setState(() {
      _filters = _filters.copyWith(
        statuses: <StockStatus>{..._filters.statuses}..remove(status),
      );
      _page = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet =
        MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;

    if (isTablet) {
      final List<Item> all = _queryAll();
      final int totalPages =
          all.isEmpty ? 1 : (all.length / _tabletPageSize).ceil();
      final int currentPage = _page.clamp(1, totalPages);
      final int start = (currentPage - 1) * _tabletPageSize;
      final List<Item> pageItems =
          all.skip(start).take(_tabletPageSize).toList();

      return Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        body: SafeArea(
          child: ItemsTabletView(
            searchController: _tabletSearch,
            filters: _filters,
            items: pageItems,
            totalCount: all.length,
            page: currentPage,
            pageSize: _tabletPageSize,
            listViewSelected: _listView,
            onSearchChanged: () => setState(() => _page = 1),
            onOpenFilters: _openFilters,
            onSortChanged: (ItemSort sort) =>
                setState(() => _filters = _filters.copyWith(sort: sort)),
            onPageChanged: (int p) => setState(() => _page = p),
            onViewModeChanged: (bool list) => setState(() => _listView = list),
            onItemTap: _openDetails,
            onRemoveStatus: _removeStatus,
            onRemoveCategory: () => setState(
              () => _filters = _filters.copyWith(category: null),
            ),
            onRemoveLocation: () => setState(
              () => _filters = _filters.copyWith(location: null),
            ),
            onClearFilters: () => setState(
              () => _filters = _filters.cleared(),
            ),
          ),
        ),
      );
    }

    final List<Item> items = ItemsRepository.query(filters: _filters);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text(AppStrings.itemsTitle),
        titleSpacing: 20,
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: SearchBox(
                      hintText: AppStrings.searchByNameHint,
                      readOnly: true,
                      onTap: _openSearch,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _FilterButton(active: _filters.isActive, onTap: _openFilters),
                ],
              ),
            ),
            if (_filters.isActive)
              _FilterChips(
                filters: _filters,
                onRemoveStatus: _removeStatus,
                onRemoveCategory: () => setState(
                  () => _filters = _filters.copyWith(category: null),
                ),
                onRemoveLocation: () => setState(
                  () => _filters = _filters.copyWith(location: null),
                ),
                onClearAll: () => setState(() => _filters = _filters.cleared()),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
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
                    '${AppStrings.sortPrefix}${_filters.sort.label}',
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
                  ? const _EmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: items.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Item item = items[index];
                        return ItemCard(
                          item: item,
                          onTap: () => _openDetails(item),
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

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.active, required this.onTap});

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
            border: Border.all(
              color: active ? AppColors.navy : AppColors.border,
            ),
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

class _FilterChips extends StatelessWidget {
  const _FilterChips({
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Row(
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
          const SizedBox(width: 8),
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
      ),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.inventory_2_outlined,
            size: 52,
            color: AppColors.textMuted,
          ),
          SizedBox(height: 12),
          Text(
            AppStrings.noItemsFound,
            style: TextStyle(color: AppColors.textMuted, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
