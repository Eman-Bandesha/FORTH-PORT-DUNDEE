import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../../dashboard/widgets/tablet_dashboard_widgets.dart';

/// Left navigation rail for tablet / iPad (logo, tabs, profile).
class TabletSideNav extends StatelessWidget {
  const TabletSideNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    required this.onProfileTap,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onProfileTap;

  static const double width = 220;

  @override
  Widget build(BuildContext context) {
    final AuthUser? user = AuthRepository.instance.currentUser;
    final String name = user?.displayName ?? AppStrings.dashboardUserName;
    final String role = user?.role.isNotEmpty == true
        ? user!.role
        : AppStrings.profileRole;

    return Container(
      width: width,
      color: AppColors.navy,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 16, 28),
              child: TabletBrandMark(),
            ),
            _NavTile(
              icon: Icons.home_rounded,
              label: AppStrings.navDashboard,
              selected: currentIndex == 0,
              onTap: () => onSelect(0),
            ),
            _NavTile(
              icon: Icons.inventory_2_rounded,
              label: AppStrings.navItems,
              selected: currentIndex == 1,
              onTap: () => onSelect(1),
            ),
            _NavTile(
              icon: Icons.swap_vert_rounded,
              label: AppStrings.navMovements,
              selected: currentIndex == 2,
              onTap: () => onSelect(2),
            ),
            _NavTile(
              icon: Icons.more_horiz_rounded,
              label: AppStrings.navMore,
              selected: currentIndex == 3,
              onTap: () => onSelect(3),
            ),
            const Spacer(),
            InkWell(
              onTap: onProfileTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: AppColors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            role,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.white.withValues(alpha: 0.75),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.white.withValues(alpha: 0.8),
                      size: 22,
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

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: selected
            ? AppColors.link.withValues(alpha: 0.35)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: <Widget>[
                Icon(
                  icon,
                  color: AppColors.white,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 14.5,
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
