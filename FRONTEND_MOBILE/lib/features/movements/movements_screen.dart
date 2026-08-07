import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/layout/app_breakpoints.dart';
import '../../core/theme/app_colors.dart';
import '../shell/widgets/tablet_menu_button.dart';
import '../items/widgets/search_box.dart';
import 'data/movements_repository.dart';
import 'models/movement.dart';
import 'models/movement_filters.dart';
import 'movement_details_screen.dart';
import 'movement_filters_screen.dart';
import 'movement_form_screen.dart';
import 'widgets/movement_tile.dart';

/// The Movements tab: stock-out (issue) movements only — overview, list, and
/// filters. Stock-in is handled elsewhere (e.g. reorder flow).
class MovementsScreen extends StatefulWidget {
  const MovementsScreen({super.key});

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen> {
  static const MovementType _type = MovementType.stockOut;

  final TextEditingController _search = TextEditingController();

  bool _showAll = false;
  MovementFilters _filters = const MovementFilters();

  @override
  void initState() {
    super.initState();
    if (!MovementsRepository.memoryMode) {
      unawaited(MovementsRepository.refresh());
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _enterList() => setState(() => _showAll = true);

  void _exitList() {
    setState(() {
      _showAll = false;
      _search.clear();
    });
  }

  Future<void> _openFilters() async {
    final MovementFilters? result = await Navigator.of(context).push(
      MaterialPageRoute<MovementFilters>(
        builder: (_) => MovementFiltersScreen(
          initial: _filters.copyWith(type: _type),
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _filters = result.copyWith(type: _type);
      _showAll = true;
    });
  }

  Future<void> _openDetails(Movement movement) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MovementDetailsScreen(movement: movement),
      ),
    );
  }

  Future<void> _openNewMovement() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const MovementFormScreen(type: _type),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet =
        MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text(AppStrings.movementsTitle),
        titleSpacing: _showAll ? 0 : 20,
        centerTitle: false,
        automaticallyImplyLeading: !_showAll && !isTablet,
        leading: _showAll
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _exitList,
              )
            : (isTablet ? const TabletMenuButton() : null),
        actions: <Widget>[
          if (!_showAll)
            IconButton(
              icon: const Icon(Icons.search_rounded),
              tooltip: AppStrings.searchHint,
              onPressed: _enterList,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _showAll ? _buildList() : _buildOverview(),
      ),
    );
  }

  Widget _buildOverview() {
    final List<Movement> recent = MovementsRepository.recent(_type);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const Text(
              AppStrings.recentMovements,
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            GestureDetector(
              onTap: _enterList,
              child: const Text(
                AppStrings.viewAll,
                style: TextStyle(
                  color: AppColors.link,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (recent.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              AppStrings.noMovementsFound,
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          )
        else
          ...recent.map(
            (Movement m) =>
                MovementTile(movement: m, onTap: () => _openDetails(m)),
          ),
        const SizedBox(height: 24),
        SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _openNewMovement,
            icon: const Icon(Icons.add_rounded, size: 22),
            label: const Text(
              AppStrings.issueStock,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    final List<Movement> movements = MovementsRepository.query(
      type: _type,
      search: _search.text,
      filters: _filters,
    );

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: <Widget>[
              Expanded(
                child: SearchBox(
                  hintText: AppStrings.searchStockOutHint,
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  onClear: () => setState(() => _search.clear()),
                ),
              ),
              const SizedBox(width: 12),
              _FilterButton(active: _filters.isActive, onTap: _openFilters),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                '${movements.length}${AppStrings.itemsCountSuffix}',
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
          child: movements.isEmpty
              ? const _EmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  itemCount: movements.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Movement m = movements[index];
                    return MovementTile(
                      movement: m,
                      onTap: () => _openDetails(m),
                    );
                  },
                ),
        ),
      ],
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.swap_vert_rounded, size: 52, color: AppColors.textMuted),
          SizedBox(height: 12),
          Text(
            AppStrings.noMovementsFound,
            style: TextStyle(color: AppColors.textMuted, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
