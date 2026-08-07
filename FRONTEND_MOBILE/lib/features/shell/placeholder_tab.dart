import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';

/// Lightweight placeholder for tabs that are not built yet (Items, Movements,
/// More). Keeps the shell navigable while those features are developed.
class PlaceholderTab extends StatelessWidget {
  const PlaceholderTab({super.key, required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(title: Text(title), titleSpacing: 20, centerTitle: false),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 56, color: AppColors.navy.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              '$title — ${AppStrings.comingSoon}',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
