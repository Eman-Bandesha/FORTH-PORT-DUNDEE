import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';

/// Navy bottom navigation bar with four destinations (no Scan).
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  /// Index into the four tab destinations (Dashboard, Items, Movements, More).
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const double _barHeight = 66;
  static const Color _inactive = Color(0x99FFFFFF);

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      height: _barHeight + bottomInset,
      padding: EdgeInsets.only(bottom: bottomInset),
      color: AppColors.navy,
      child: Row(
        children: <Widget>[
          _NavItem(
            icon: Icons.home_rounded,
            label: AppStrings.navDashboard,
            selected: currentIndex == 0,
            activeColor: AppColors.white,
            inactiveColor: _inactive,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.inventory_2_rounded,
            label: AppStrings.navItems,
            selected: currentIndex == 1,
            activeColor: AppColors.white,
            inactiveColor: _inactive,
            onTap: () => onTap(1),
          ),
          _NavItem(
            icon: Icons.swap_vert_rounded,
            label: AppStrings.navMovements,
            selected: currentIndex == 2,
            activeColor: AppColors.white,
            inactiveColor: _inactive,
            onTap: () => onTap(2),
          ),
          _NavItem(
            icon: Icons.more_horiz_rounded,
            label: AppStrings.navMore,
            selected: currentIndex == 3,
            activeColor: AppColors.white,
            inactiveColor: _inactive,
            onTap: () => onTap(3),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? activeColor : inactiveColor;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
