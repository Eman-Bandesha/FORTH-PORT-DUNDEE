import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/api/api_exception.dart';
import '../../shared/widgets/primary_button.dart';
import 'auth_success_screen.dart';
import 'data/auth_repository.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/password_strength_meter.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.resetToken});

  final String resetToken;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  final FocusNode _confirmFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitting = false;
  PasswordStrength _strength = PasswordStrength.none;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return AppStrings.newPasswordRequired;
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.confirmPasswordRequired;
    }
    if (value != _password.text) return AppStrings.passwordsDoNotMatch;
    return null;
  }

  Future<void> _onReset() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await AuthRepository.instance.resetPassword(
        resetToken: widget.resetToken,
        newPassword: _password.text,
        confirmPassword: _confirm.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const PasswordResetSuccessScreen(),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AuthScaffold(
      children: <Widget>[
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                AppStrings.resetPasswordTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a new password, then sign in again.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 24),
              AuthTextField(
                controller: _password,
                hintText: AppStrings.newPasswordLabel,
                prefixIcon: Icons.lock_outline,
                obscureText: _obscurePassword,
                onChanged: (String v) => setState(() {
                  _strength = PasswordStrength.of(v);
                }),
                suffix: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
                validator: _validatePassword,
                onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
              ),
              PasswordStrengthMeter(strength: _strength),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _confirm,
                focusNode: _confirmFocus,
                hintText: AppStrings.confirmPasswordLabel,
                prefixIcon: Icons.lock_outline,
                obscureText: _obscureConfirm,
                suffix: IconButton(
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
                validator: _validateConfirm,
                onFieldSubmitted: (_) => _onReset(),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: AppStrings.resetPasswordCta,
                loading: _submitting,
                onPressed: _onReset,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
