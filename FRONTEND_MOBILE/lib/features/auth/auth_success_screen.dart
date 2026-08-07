import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/primary_button.dart';
import '../shell/main_shell.dart';

/// Generic confirmation screen: a large illustration, a title/message and a
/// single primary action. Reused for the various "success" states so they stay
/// visually consistent.
class AuthSuccessScreen extends StatelessWidget {
  const AuthSuccessScreen({
    super.key,
    required this.illustration,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  final Widget illustration;
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.darkStatusBar,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: <Widget>[
                    const Spacer(flex: 3),
                    illustration,
                    const SizedBox(height: 32),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                    const Spacer(flex: 4),
                    PrimaryButton(label: buttonLabel, onPressed: onPressed),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown after a successful password reset.
class PasswordResetSuccessScreen extends StatelessWidget {
  const PasswordResetSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthSuccessScreen(
      illustration: const _CheckBurst(),
      title: AppStrings.passwordResetSuccessTitle,
      message: AppStrings.passwordResetSuccessMessage,
      buttonLabel: AppStrings.backToLogin,
      // Clear the whole auth stack and return to sign-in.
      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
    );
  }
}

/// Shown after a successful sign-in.
class LoginSuccessScreen extends StatelessWidget {
  const LoginSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthSuccessScreen(
      illustration: const _LockBadge(),
      title: AppStrings.loginSuccessTitle,
      message: AppStrings.loginSuccessMessage,
      buttonLabel: AppStrings.goToDashboard,
      onPressed: () => Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const MainShell()),
        (route) => false,
      ),
    );
  }
}

/// Green success check inside a soft halo (password reset).
class _CheckBurst extends StatelessWidget {
  const _CheckBurst();

  @override
  Widget build(BuildContext context) {
    const Color green = Color(0xFF22B573);
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: green.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 92,
          height: 92,
          decoration: const BoxDecoration(color: green, shape: BoxShape.circle),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.white,
            size: 52,
          ),
        ),
      ),
    );
  }
}

/// Navy padlock with a small green check badge (login success).
class _LockBadge extends StatelessWidget {
  const _LockBadge();

  @override
  Widget build(BuildContext context) {
    const Color green = Color(0xFF22B573);
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
          ),
          const Icon(Icons.lock_rounded, color: AppColors.navy, size: 68),
          Positioned(
            right: 18,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: green,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2.5),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
