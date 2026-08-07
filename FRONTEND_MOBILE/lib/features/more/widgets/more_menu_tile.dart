import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// A tappable row on the More menu (icon, title, chevron).
class MoreMenuTile extends StatelessWidget {
  const MoreMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.titleColor = AppColors.navy,
    this.iconColor = AppColors.navy,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color titleColor;
  final Color iconColor;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (showChevron)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
