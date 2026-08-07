import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_snackbar.dart';
import '../items/data/items_repository.dart';
import '../items/models/item.dart';
import '../items/models/item_filters.dart';
import 'reorder_items_screen.dart';

/// Notifications overview. Per the brief this only surfaces the two actionable
/// alert types — Out of Stock (high priority) and Low Stock (warnings).
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static int countFor(StockStatus status) => ItemsRepository.query(
    filters: ItemFilters(statuses: <StockStatus>{status}),
  ).length;

  void _open(BuildContext context, StockStatus status) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReorderItemsScreen(status: status),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int outOfStock = countFor(StockStatus.outOfStock);
    final int lowStock = countFor(StockStatus.lowStock);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text(AppStrings.notificationsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () =>
                AppSnackBar.success(context, AppStrings.allMarkedRead),
            style: TextButton.styleFrom(foregroundColor: AppColors.white),
            child: const Text(
              AppStrings.markAllRead,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: <Widget>[
            const _SectionLabel(AppStrings.highPriority),
            const SizedBox(height: 12),
            _NotificationCard(
              icon: Icons.inventory_rounded,
              accent: AppColors.red,
              background: const Color(0xFFFBE7E6),
              title: AppStrings.outOfStockItemsTitle,
              body: '$outOfStock ${AppStrings.outOfStockNotifBody}',
              onTap: () => _open(context, StockStatus.outOfStock),
            ),
            const SizedBox(height: 26),
            const _SectionLabel(AppStrings.warnings),
            const SizedBox(height: 12),
            _NotificationCard(
              icon: Icons.warning_amber_rounded,
              accent: const Color(0xFFC9821B),
              background: const Color(0xFFFCF1DE),
              title: AppStrings.lowStockItemsTitle,
              body: '$lowStock ${AppStrings.lowStockNotifBody}',
              onTap: () => _open(context, StockStatus.lowStock),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.icon,
    required this.accent,
    required this.background,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final Color background;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}
