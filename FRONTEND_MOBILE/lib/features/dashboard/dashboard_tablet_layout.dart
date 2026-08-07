import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../auth/data/auth_repository.dart';
import '../dashboard/data/dashboard_repository.dart';
import '../items/data/items_repository.dart';
import '../items/models/item.dart';
import '../items/models/item_filters.dart';
import '../movements/data/movements_repository.dart';
import '../movements/models/movement.dart';
import '../notifications/notifications_screen.dart';
import '../notifications/reorder_items_screen.dart';
import 'widgets/dashboard_notification_bell.dart';
import 'widgets/tablet_dashboard_widgets.dart';
import '../shell/widgets/tablet_menu_button.dart';

/// Tablet / iPad dashboard (sidebar is provided by [MainShell]).
class DashboardTabletLayout extends StatelessWidget {
  const DashboardTabletLayout({
    super.key,
    required this.onSelectTab,
    required this.onShowAccountMenu,
  });

  final ValueChanged<int>? onSelectTab;
  final VoidCallback onShowAccountMenu;

  int _countFor(StockStatus status) => ItemsRepository.query(
    filters: ItemFilters(statuses: <StockStatus>{status}),
  ).length;

  void _openNotifications(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
    );
  }

  void _openStatus(BuildContext context, StockStatus status) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReorderItemsScreen(status: status),
      ),
    );
  }

  void _openMovements(BuildContext context) {
    onSelectTab?.call(2);
  }

  @override
  Widget build(BuildContext context) {
    final int lowStock = _countFor(StockStatus.lowStock);
    final int outOfStock = _countFor(StockStatus.outOfStock);
    final int alertCount = lowStock + outOfStock;
    final DashboardStats? dash = DashboardRepository.cached;
    final int totalItems =
        dash?.totalItems ?? ItemsRepository.all.length;
    final int stockOutToday =
        dash?.stockOutToday ?? MovementsRepository.stockOutTodayCount;
    final List<Movement> recentOut = dash != null &&
            dash.recentStockOut.isNotEmpty
        ? dash.recentStockOut.take(3).toList()
        : MovementsRepository.recent(
            MovementType.stockOut,
            limit: 3,
          );

    return ColoredBox(
      color: const Color(0xFFF6F8FB),
      child: Column(
        children: <Widget>[
          _TabletTopBar(
            alertCount: alertCount,
            onNotifications: () => _openNotifications(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 24),
                  InkWell(
                    onTap: onShowAccountMenu,
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Hello, ${AuthRepository.instance.currentUser?.displayName ?? 'there'}',
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          AppStrings.dashboardSubtitle,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      int columns = 4;
                      if (constraints.maxWidth < 900) columns = 2;
                      final double gap = 16;
                      final double cardWidth =
                          (constraints.maxWidth - gap * (columns - 1)) /
                          columns;

                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: <Widget>[
                          SizedBox(
                            width: cardWidth,
                            child: TabletStatCard(
                              label: AppStrings.statTotalItems,
                              value: _formatCount(totalItems),
                              icon: Icons.inventory_2_rounded,
                              iconColor: AppColors.link,
                              linkLabel: AppStrings.viewAllItemsLink,
                              onTap: () => onSelectTab?.call(1),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: TabletStatCard(
                              label: AppStrings.statLowStock,
                              value: '$lowStock',
                              icon: Icons.error_outline_rounded,
                              iconColor: const Color(0xFFE8A33D),
                              linkLabel: AppStrings.viewLowStockLink,
                              onTap: () =>
                                  _openStatus(context, StockStatus.lowStock),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: TabletStatCard(
                              label: AppStrings.statOutOfStock,
                              value: '$outOfStock',
                              icon: Icons.cancel_outlined,
                              iconColor: AppColors.red,
                              linkLabel: AppStrings.viewOutOfStockLink,
                              onTap: () => _openStatus(
                                context,
                                StockStatus.outOfStock,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: TabletStatCard(
                              label: AppStrings.statStockOutToday,
                              value: '$stockOutToday',
                              icon: Icons.outbox_rounded,
                              iconColor: const Color(0xFF1E8E54),
                              linkLabel: AppStrings.viewRecentStockOutLink,
                              onTap: () => _openMovements(context),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        flex: 5,
                        child: _QuickActionsPanel(
                          onSelectTab: onSelectTab,
                          onAlerts: () => _openNotifications(context),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 6,
                        child: Column(
                          children: <Widget>[
                            _AlertsPanel(
                              outOfStock: outOfStock,
                              lowStock: lowStock,
                              onViewAll: () => _openNotifications(context),
                              onOutOfStock: () => _openStatus(
                                context,
                                StockStatus.outOfStock,
                              ),
                              onLowStock: () => _openStatus(
                                context,
                                StockStatus.lowStock,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _RecentStockOutPanel(
                              movements: recentOut,
                              onViewAll: () => _openMovements(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Center(
                    child: Text(
                      AppStrings.appVersionFooter,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12.5,
                      ),
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

  static String _formatCount(int n) {
    if (n >= 1000) {
      return '${n ~/ 1000},${(n % 1000).toString().padLeft(3, '0')}';
    }
    return '$n';
  }
}

class _TabletTopBar extends StatelessWidget {
  const _TabletTopBar({
    required this.alertCount,
    required this.onNotifications,
  });

  final int alertCount;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: AppColors.navy,
      child: Row(
        children: <Widget>[
          const TabletMenuButton(),
          const SizedBox(width: 4),
          const TabletBrandMark(compact: true),
          const Spacer(),
          DashboardNotificationBell(
            count: alertCount,
            onTap: onNotifications,
            iconColor: AppColors.white,
            badgeBorderColor: AppColors.navy,
          ),
        ],
      ),
    );
  }
}

class _QuickActionsPanel extends StatelessWidget {
  const _QuickActionsPanel({
    required this.onSelectTab,
    required this.onAlerts,
  });

  final ValueChanged<int>? onSelectTab;
  final VoidCallback onAlerts;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 8),
            child: Text(
              AppStrings.quickActions,
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TabletQuickActionTile(
            icon: Icons.inventory_2_outlined,
            iconColor: const Color(0xFF1E8E54),
            title: AppStrings.actionBrowseItems,
            subtitle: AppStrings.actionBrowseItemsSub,
            onTap: () => onSelectTab?.call(1),
          ),
          const Divider(height: 1, indent: 18, endIndent: 18),
          TabletQuickActionTile(
            icon: Icons.outbox_rounded,
            iconColor: const Color(0xFF8E5BD0),
            title: AppStrings.actionIssueStock,
            subtitle: AppStrings.actionIssueStockSub,
            onTap: () => onSelectTab?.call(2),
          ),
          const Divider(height: 1, indent: 18, endIndent: 18),
          TabletQuickActionTile(
            icon: Icons.notifications_active_outlined,
            iconColor: const Color(0xFFE8A33D),
            title: AppStrings.actionViewAlerts,
            subtitle: AppStrings.actionViewAlertsSub,
            onTap: onAlerts,
          ),
        ],
      ),
    );
  }
}

class _AlertsPanel extends StatelessWidget {
  const _AlertsPanel({
    required this.outOfStock,
    required this.lowStock,
    required this.onViewAll,
    required this.onOutOfStock,
    required this.onLowStock,
  });

  final int outOfStock;
  final int lowStock;
  final VoidCallback onViewAll;
  final VoidCallback onOutOfStock;
  final VoidCallback onLowStock;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  AppStrings.alertsTitle,
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onViewAll,
                child: const Text(
                  '${AppStrings.viewAllAlerts} >',
                  style: TextStyle(
                    color: AppColors.link,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _AlertRow(
            tint: const Color(0xFFFBE7E6),
            icon: Icons.cancel_rounded,
            iconColor: AppColors.red,
            title: AppStrings.outOfStockItemsTitle,
            subtitle: '$outOfStock ${AppStrings.itemsNeedAttention}',
            value: '$outOfStock',
            valueColor: AppColors.red,
            onTap: onOutOfStock,
          ),
          const SizedBox(height: 10),
          _AlertRow(
            tint: const Color(0xFFFCF1DE),
            icon: Icons.error_outline_rounded,
            iconColor: const Color(0xFFE8A33D),
            title: AppStrings.lowStockItemsTitle,
            subtitle: '$lowStock ${AppStrings.itemsRunningLow}',
            value: '$lowStock',
            valueColor: const Color(0xFFE8A33D),
            onTap: onLowStock,
          ),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.tint,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.valueColor,
    required this.onTap,
  });

  final Color tint;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String value;
  final Color valueColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tint,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: <Widget>[
              Icon(icon, color: iconColor, size: 22),
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
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentStockOutPanel extends StatelessWidget {
  const _RecentStockOutPanel({
    required this.movements,
    required this.onViewAll,
  });

  final List<Movement> movements;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  AppStrings.recentStockOutTitle,
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onViewAll,
                child: const Text(
                  '${AppStrings.viewAll} >',
                  style: TextStyle(
                    color: AppColors.link,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            children: <Widget>[
              Expanded(
                flex: 4,
                child: Text(
                  AppStrings.itemHeader,
                  style: _tableHeader,
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  AppStrings.dateTimeHeader,
                  style: _tableHeader,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  AppStrings.issuedToHeader,
                  style: _tableHeader,
                ),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  AppStrings.qtyIssuedHeader,
                  textAlign: TextAlign.end,
                  style: _tableHeader,
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.border),
          if (movements.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                AppStrings.noMovementsFound,
                style: TextStyle(color: AppColors.textMuted),
              ),
            )
          else
            for (final Movement m in movements) ...<Widget>[
              _StockOutRow(movement: m),
              const Divider(height: 1, color: AppColors.border),
            ],
        ],
      ),
    );
  }
}

const TextStyle _tableHeader = TextStyle(
  color: AppColors.textMuted,
  fontSize: 12,
  fontWeight: FontWeight.w700,
);

class _StockOutRow extends StatelessWidget {
  const _StockOutRow({required this.movement});

  final Movement movement;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Row(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    movement.image,
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
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        movement.itemName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        movement.itemCode,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              movement.dateTimeLabel,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              movement.requestedBy,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(
              '${movement.quantity}',
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
