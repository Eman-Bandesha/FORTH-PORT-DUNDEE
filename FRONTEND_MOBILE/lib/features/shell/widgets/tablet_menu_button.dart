import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../tablet_shell_scope.dart';

/// Hamburger control to show/hide the tablet sidebar ([TabletShellScope]).
class TabletMenuButton extends StatelessWidget {
  const TabletMenuButton({super.key, this.iconColor = AppColors.white});

  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final TabletShellScope? scope = TabletShellScope.maybeOf(context);
    if (scope == null) return const SizedBox.shrink();

    return IconButton(
      onPressed: scope.toggleNav,
      icon: Icon(Icons.menu_rounded, color: iconColor),
      tooltip: AppStrings.toggleNavMenu,
    );
  }
}
