import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import 'data/items_repository.dart';
import 'edit_item_screen.dart';
import 'models/item.dart';
import 'models/stock_analytics.dart';
import 'models/stock_movement.dart';
import 'widgets/stock_status_badge.dart';
import 'widgets/stock_trend_chart.dart';

/// Result returned from [ItemDetailsScreen] so callers can refresh / notify.
enum ItemDetailsResult { updated }

/// Detail view for a single [Item], with Overview and Stock & History tabs.
class ItemDetailsScreen extends StatefulWidget {
  const ItemDetailsScreen({super.key, required this.item});

  final Item item;

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Item _item;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _comingSoon(String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$label — ${AppStrings.comingSoon}')),
      );
  }

  Future<void> _onEdit() async {
    final Item? updated = await Navigator.of(context).push(
      MaterialPageRoute<Item>(builder: (_) => EditItemScreen(item: _item)),
    );
    if (updated != null && mounted) {
      setState(() {
        _item = updated;
        _changed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Item item = _item;
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        Navigator.of(context).pop(_changed ? ItemDetailsResult.updated : null);
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: const Text(AppStrings.itemDetailsTitle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(
              context,
            ).pop(_changed ? ItemDetailsResult.updated : null),
          ),
          actions: const <Widget>[
            SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                children: <Widget>[
                  _Header(item: item),
                  const SizedBox(height: 20),
                  _Tabs(controller: _tabController),
                  const SizedBox(height: 4),
                  if (_tabController.index == 0)
                    _OverviewTab(item: item)
                  else
                    _StockHistoryTab(item: item),
                ],
              ),
            ),
            _BottomActions(
              onEdit: _onEdit,
              onMovement: () => _comingSoon(AppStrings.stockMovementCta),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              item.image,
              height: 150,
              width: 150,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 150,
                width: 150,
                color: AppColors.fieldFill,
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          item.name,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.code,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
        const SizedBox(height: 12),
        StockStatusBadge(status: item.status),
      ],
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      labelColor: AppColors.navy,
      unselectedLabelColor: AppColors.textMuted,
      indicatorColor: AppColors.navy,
      indicatorWeight: 2.5,
      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      tabs: const <Widget>[
        Tab(text: AppStrings.tabOverview),
        Tab(text: AppStrings.tabStockHistory),
      ],
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 12),
        _DetailRow(label: AppStrings.detailCategory, value: item.category),
        _DetailRow(
          label: AppStrings.detailCurrentStock,
          value: '${item.quantity}',
        ),
        _DetailRow(label: AppStrings.detailUnit, value: item.unit),
        _DetailRow(
          label: AppStrings.detailReorderLevel,
          value: '${item.reorderLevel}',
        ),
        _DetailRow(label: AppStrings.detailLocation, value: item.location),
        const SizedBox(height: 18),
        const Text(
          AppStrings.detailDescription,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          item.description,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 15,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          AppStrings.detailLastUpdated,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          item.lastUpdated,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockHistoryTab extends StatefulWidget {
  const _StockHistoryTab({required this.item});

  final Item item;

  @override
  State<_StockHistoryTab> createState() => _StockHistoryTabState();
}

class _StockHistoryTabState extends State<_StockHistoryTab> {
  late Future<StockAnalytics> _analytics;

  @override
  void initState() {
    super.initState();
    _analytics = ItemsRepository.analyticsFor(widget.item);
  }

  @override
  Widget build(BuildContext context) {
    final Item item = widget.item;
    return FutureBuilder<StockAnalytics>(
      future: _analytics,
      builder: (BuildContext context, AsyncSnapshot<StockAnalytics> snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final StockAnalytics analytics = snap.data!;
        return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 16),
        const _SectionTitle(AppStrings.stockSummary),
        const SizedBox(height: 12),
        _SummaryStrip(analytics: analytics),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _SectionTitle(AppStrings.stockTrendTitle),
              const SizedBox(height: 16),
              StockTrendChart(trend: analytics.trend),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _SectionTitle(AppStrings.lastActivityTitle),
        const SizedBox(height: 12),
        _ActivityTile(
          title: AppStrings.lastStockIn,
          movement: analytics.lastIn,
          unit: item.unit,
        ),
        const SizedBox(height: 12),
        _ActivityTile(
          title: AppStrings.lastStockOut,
          movement: analytics.lastOut,
          unit: item.unit,
        ),
      ],
    );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.navy,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.analytics});

  final StockAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: <Widget>[
            Expanded(
              child: _SummaryMetric(
                label: AppStrings.summaryInStock,
                value: '${analytics.inStock}',
                color: const Color(0xFF1E8E54),
              ),
            ),
            const _MetricDivider(),
            Expanded(
              child: _SummaryMetric(
                label: AppStrings.summaryStockInTotal,
                value: '${analytics.stockInTotal}',
                color: AppColors.link,
              ),
            ),
            const _MetricDivider(),
            Expanded(
              child: _SummaryMetric(
                label: AppStrings.summaryStockOutTotal,
                value: '${analytics.stockOutTotal}',
                color: AppColors.red,
              ),
            ),
            const _MetricDivider(),
            Expanded(
              child: _SummaryMetric(
                label: AppStrings.summaryReorderLevel,
                value: '${analytics.reorderLevel}',
                color: const Color(0xFFC9821B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return const VerticalDivider(
      width: 1,
      thickness: 1,
      color: AppColors.border,
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: 30,
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.title,
    required this.movement,
    required this.unit,
  });

  final String title;
  final StockMovement movement;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final Color accent = movement.type.color;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(movement.type.icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  movement.dateTime,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '${movement.changeLabel} $unit',
                style: TextStyle(
                  color: accent,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                movement.location,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.onEdit, required this.onMovement});

  final VoidCallback onEdit;
  final VoidCallback onMovement;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: <Widget>[
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: onEdit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  side: const BorderSide(color: AppColors.navy, width: 1.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  AppStrings.editItem,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: onMovement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  AppStrings.stockMovementCta,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
