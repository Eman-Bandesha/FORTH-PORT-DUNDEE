import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/layout/app_breakpoints.dart';
import '../../core/theme/app_colors.dart';
import '../shell/widgets/tablet_menu_button.dart';
import '../auth/data/auth_repository.dart';
import '../auth/login_screen.dart';
import 'about_screen.dart';
import 'help_support_screen.dart';
import 'my_profile_screen.dart';
import 'widgets/logout_dialog.dart';
import 'widgets/more_menu_tile.dart';

/// More tab: profile header, settings links, and logout.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final bool? confirmed = await showLogoutDialog(context);
    if (confirmed == true && context.mounted) {
      await AuthRepository.instance.logout();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet =
        MediaQuery.sizeOf(context).width >= AppBreakpoints.tablet;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text(AppStrings.moreTitle),
        titleSpacing: 20,
        centerTitle: false,
        automaticallyImplyLeading: !isTablet,
        leading: isTablet ? const TabletMenuButton() : null,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: <Widget>[
            const _ProfileHeader(),
            const SizedBox(height: 24),
            MoreMenuTile(
              icon: Icons.person_outline_rounded,
              title: AppStrings.myProfile,
              onTap: () => _open(context, const MyProfileScreen()),
            ),
            const SizedBox(height: 12),
            MoreMenuTile(
              icon: Icons.help_outline_rounded,
              title: AppStrings.helpSupport,
              onTap: () => _open(context, const HelpSupportScreen()),
            ),
            const SizedBox(height: 12),
            MoreMenuTile(
              icon: Icons.info_outline_rounded,
              title: AppStrings.aboutApp,
              onTap: () => _open(context, const AboutScreen()),
            ),
            const SizedBox(height: 12),
            MoreMenuTile(
              icon: Icons.logout_rounded,
              title: AppStrings.logout,
              titleColor: AppColors.red,
              iconColor: AppColors.red,
              showChevron: false,
              onTap: () => _confirmLogout(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    final AuthUser? user = AuthRepository.instance.currentUser;
    final String name = user?.displayName ?? AppStrings.dashboardUserName;
    final String role =
        user?.role.isNotEmpty == true ? user!.role : AppStrings.profileRole;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0A0A2240),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.navy,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
