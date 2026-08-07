import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../auth/data/auth_repository.dart';
import '../auth/force_change_password_screen.dart';

/// My Profile — read-only user details and change-password entry.
class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  void _changePassword(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ForceChangePasswordScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthUser? user = AuthRepository.instance.currentUser;
    final String name = user?.displayName ?? '—';
    final String role =
        user?.role.isNotEmpty == true ? user!.role : '—';
    final String department =
        user?.department.isNotEmpty == true ? user!.department : '—';
    final String email =
        user?.email.isNotEmpty == true ? user!.email : '—';
    final String phone =
        user?.phone.isNotEmpty == true ? user!.phone : '—';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text(AppStrings.myProfile),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: <Widget>[
          _ProfileRow(
            icon: Icons.person_outline_rounded,
            label: AppStrings.fullNameLabel,
            value: name,
          ),
          _ProfileRow(
            icon: Icons.badge_outlined,
            label: AppStrings.roleLabel,
            value: role,
          ),
          _ProfileRow(
            icon: Icons.apartment_rounded,
            label: AppStrings.departmentLabel,
            value: department,
          ),
          _ProfileRow(
            icon: Icons.mail_outline_rounded,
            label: AppStrings.emailLabel,
            value: email,
          ),
          _ProfileRow(
            icon: Icons.phone_outlined,
            label: AppStrings.phoneLabel,
            value: phone,
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _changePassword(context),
              icon: const Icon(Icons.lock_outline_rounded),
              label: const Text(AppStrings.changePassword),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.link,
                side: const BorderSide(color: AppColors.link),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: AppColors.navy, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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
