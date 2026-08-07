import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_snackbar.dart';
import '../auth/data/auth_repository.dart';
import '../auth/login_screen.dart';
import '../items/create_item_screen.dart';
import '../dashboard/data/dashboard_repository.dart';
import '../items/data/items_repository.dart';
import '../items/models/item.dart';
import '../items/models/item_filters.dart';
import '../notifications/notifications_screen.dart';
import '../notifications/reorder_items_screen.dart';
import '../../core/layout/app_breakpoints.dart';
import 'dashboard_tablet_layout.dart';
import 'widgets/dashboard_notification_bell.dart';
import 'widgets/quick_action_tile.dart';
import 'widgets/stat_card.dart';

/// Main dashboard: greeting, key stock metrics and quick actions.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    this.onSelectTab,
    this.isTabletLayout = false,
  });

  /// Switches the host shell to another primary tab (Movements, More, ...).
  final ValueChanged<int>? onSelectTab;

  /// When true, renders the wide tablet dashboard (shell provides sidebar).
  final bool isTabletLayout;

  void _notImplemented(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$label — ${AppStrings.comingSoon}')),
      );
  }

  Future<void> _openCreateItem(BuildContext context) async {
    final Item? created = await Navigator.of(context).push<Item>(
      MaterialPageRoute<Item>(builder: (_) => const CreateItemScreen()),
    );
    if (created != null && context.mounted) {
      AppSnackBar.success(context, AppStrings.itemCreated);
    }
  }

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

  Future<void> _showAccountMenu(BuildContext context) async {
    final bool? logout = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 10),
              const _AccountHeader(),
              const Divider(height: 1, color: AppColors.border),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppColors.red),
                title: const Text(
                  AppStrings.logOut,
                  style: TextStyle(
                    color: AppColors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () => Navigator.of(sheetContext).pop(true),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (logout == true && context.mounted) {
      await AuthRepository.instance.logout();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  int _countFor(StockStatus status) => ItemsRepository.query(
    filters: ItemFilters(statuses: <StockStatus>{status}),
  ).length;

  @override
  Widget build(BuildContext context) {
    final int lowStock = _countFor(StockStatus.lowStock);
    final int outOfStock = _countFor(StockStatus.outOfStock);
    final int alertCount = lowStock + outOfStock;
    final DashboardStats? stats = DashboardRepository.cached;
    final String totalItemsLabel = stats != null
        ? '${stats.totalItems}'
        : '${ItemsRepository.all.length}';
    final String nearExpiryLabel =
        stats != null ? '${stats.nearExpiry}' : '0';

    final bool useTablet = isTabletLayout ||
        MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;

    if (useTablet) {
      return DashboardTabletLayout(
        onSelectTab: onSelectTab,
        onShowAccountMenu: () => _showAccountMenu(context),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text(AppStrings.dashboardTitle),
        titleSpacing: 20,
        centerTitle: false,
        actions: <Widget>[
          DashboardNotificationBell(
            count: alertCount,
            onTap: () => _openNotifications(context),
            badgeBorderColor: AppColors.navy,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: <Widget>[
            _Greeting(onTap: () => _showAccountMenu(context)),
            const SizedBox(height: 4),
            const Text(
              AppStrings.dashboardSubtitle,
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 22),
            _StatsGrid(
              lowStock: lowStock,
              outOfStock: outOfStock,
              totalItems: totalItemsLabel,
              nearExpiry: nearExpiryLabel,
              onOpenStatus: (StockStatus status) =>
                  _openStatus(context, status),
              onOther: (String label) => _notImplemented(context, label),
            ),
            const SizedBox(height: 30),
            const Text(
              AppStrings.quickActions,
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            _QuickActionsCard(
              onBrowseItems: () => onSelectTab?.call(1),
              onAddItem: () => _openCreateItem(context),
              onStockMovement: () => onSelectTab?.call(2),
              onMore: () => onSelectTab?.call(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String name =
        AuthRepository.instance.currentUser?.displayName ?? 'there';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: <Widget>[
            Flexible(
              child: Text(
                'Hello, $name',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader();

  @override
  Widget build(BuildContext context) {
    final AuthUser? user = AuthRepository.instance.currentUser;
    final String name = user?.displayName ?? AppStrings.dashboardUserName;
    final String subtitle = user?.role.isNotEmpty == true
        ? user!.role
        : AppStrings.account;
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.navy.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.person_rounded, color: AppColors.navy),
      ),
      title: Text(
        name,
        style: const TextStyle(
          color: AppColors.navy,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textMuted),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.lowStock,
    required this.outOfStock,
    required this.totalItems,
    required this.nearExpiry,
    required this.onOpenStatus,
    required this.onOther,
  });

  final int lowStock;
  final int outOfStock;
  final String totalItems;
  final String nearExpiry;
  final ValueChanged<StockStatus> onOpenStatus;
  final ValueChanged<String> onOther;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.35,
      children: <Widget>[
        StatCard(
          label: AppStrings.statTotalItems,
          value: totalItems,
          icon: Icons.inventory_2_rounded,
          iconColor: AppColors.link,
          onTap: () => onOther(AppStrings.statTotalItems),
        ),
        StatCard(
          label: AppStrings.statLowStock,
          value: '$lowStock',
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFE8A33D),
          onTap: () => onOpenStatus(StockStatus.lowStock),
        ),
        StatCard(
          label: AppStrings.statOutOfStock,
          value: '$outOfStock',
          icon: Icons.inventory_rounded,
          iconColor: AppColors.red,
          onTap: () => onOpenStatus(StockStatus.outOfStock),
        ),
        StatCard(
          label: AppStrings.statNearExpiry,
          value: nearExpiry,
          icon: Icons.event_note_rounded,
          iconColor: const Color(0xFF22B573),
          onTap: () => onOther(AppStrings.statNearExpiry),
        ),
      ],
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({
    required this.onBrowseItems,
    required this.onAddItem,
    required this.onStockMovement,
    required this.onMore,
  });

  final VoidCallback onBrowseItems;
  final VoidCallback onAddItem;
  final VoidCallback onStockMovement;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0F0A2240),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: <Widget>[
            QuickActionTile(
              icon: Icons.inventory_2_outlined,
              title: AppStrings.actionBrowseItems,
              subtitle: AppStrings.actionBrowseItemsSub,
              onTap: onBrowseItems,
            ),
            const _TileDivider(),
            QuickActionTile(
              icon: Icons.add_circle_outline_rounded,
              title: AppStrings.actionAddItem,
              subtitle: AppStrings.actionAddItemSub,
              onTap: onAddItem,
            ),
            const _TileDivider(),
            QuickActionTile(
              icon: Icons.sync_alt_rounded,
              title: AppStrings.actionStockMovement,
              subtitle: AppStrings.actionStockMovementSub,
              onTap: onStockMovement,
            ),
            const _TileDivider(),
            QuickActionTile(
              icon: Icons.more_horiz_rounded,
              title: AppStrings.actionMore,
              subtitle: AppStrings.actionMoreSub,
              onTap: onMore,
            ),
          ],
        ),
      ),
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: AppColors.border,
    );
  }
}
