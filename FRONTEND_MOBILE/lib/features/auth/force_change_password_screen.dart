import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/app_snackbar.dart';
import '../../shared/widgets/primary_button.dart';
import 'auth_success_screen.dart';
import 'data/auth_repository.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/auth_text_field.dart';

/// Forced password change after admin-issued temporary password.
class ForceChangePasswordScreen extends StatefulWidget {
  const ForceChangePasswordScreen({super.key});

  @override
  State<ForceChangePasswordScreen> createState() =>
      _ForceChangePasswordScreenState();
}

class _ForceChangePasswordScreenState extends State<ForceChangePasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _current = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _submitting = false;
  bool _obscureCurrent = true;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await AuthRepository.instance.changePassword(
        currentPassword: _current.text,
        newPassword: _password.text,
        confirmPassword: _confirm.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginSuccessScreen()),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (mounted) AppSnackBar.error(context, e.message);
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(context, 'Could not update password. Try again.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AuthScaffold(
      children: <Widget>[
        Text(
          'Change your password',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
            fontSize: context.isTablet ? 28 : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your administrator gave you a temporary password. '
          'Please set a new password before continuing.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textMuted,
            height: 1.4,
            fontSize: context.isTablet ? 16 : null,
          ),
        ),
        const SizedBox(height: 24),
        Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              AuthTextField(
                controller: _current,
                hintText: 'Current (temporary) password',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscureCurrent,
                suffix: IconButton(
                  onPressed: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                  icon: Icon(
                    _obscureCurrent ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
                validator: (String? v) => (v == null || v.isEmpty)
                    ? AppStrings.passwordRequired
                    : null,
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _password,
                hintText: AppStrings.newPasswordLabel,
                prefixIcon: Icons.lock_rounded,
                obscureText: _obscurePassword,
                suffix: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
                validator: (String? v) {
                  if (v == null || v.isEmpty) {
                    return AppStrings.newPasswordRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _confirm,
                hintText: AppStrings.confirmPasswordLabel,
                prefixIcon: Icons.lock_rounded,
                obscureText: _obscureConfirm,
                suffix: IconButton(
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
                validator: (String? v) {
                  if (v != _password.text) {
                    return AppStrings.passwordsDoNotMatch;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Save new password',
                loading: _submitting,
                onPressed: _onSubmit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
