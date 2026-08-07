import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';

/// Dashboard app-bar notification bell with optional badge count.
class DashboardNotificationBell extends StatelessWidget {
  const DashboardNotificationBell({
    super.key,
    required this.count,
    required this.onTap,
    this.iconColor = AppColors.navy,
    this.badgeBorderColor = AppColors.white,
  });

  final int count;
  final VoidCallback onTap;
  final Color iconColor;
  final Color badgeBorderColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        IconButton(
          onPressed: onTap,
          icon: Icon(Icons.notifications_none_rounded, color: iconColor),
          tooltip: AppStrings.notificationsTitle,
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: BoxDecoration(
                color: AppColors.red,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: badgeBorderColor, width: 1.5),
              ),
              child: Text(
                count > 9 ? '9+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
