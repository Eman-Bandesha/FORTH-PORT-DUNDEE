import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_snackbar.dart';
import '../../shared/widgets/primary_button.dart';
import 'data/auth_repository.dart';
import 'widgets/auth_footer_link.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/auth_text_field.dart';

/// Account creation screen.
///
/// Collects the new user's details with inline validation and a confirm-password
/// match check. (Per request, there is no terms & conditions checkbox.)
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitting = false;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _username.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _emailFocus.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final String email = (value ?? '').trim();
    if (email.isEmpty) return AppStrings.emailRequired;
    final RegExp pattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    if (!pattern.hasMatch(email)) return AppStrings.emailInvalid;
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return AppStrings.passwordRequired;
    if (value.length < 6) return AppStrings.passwordTooShort;
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.confirmPasswordRequired;
    }
    if (value != _password.text) return AppStrings.passwordsDoNotMatch;
    return null;
  }

  Future<void> _onSignUp() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final List<String> nameParts = _fullName.text.trim().split(RegExp(r'\s+'));
      final String first = nameParts.isNotEmpty ? nameParts.first : '';
      final String last =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      await AuthRepository.instance.register(
        username: _username.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        firstName: first,
        lastName: last,
      );
      if (!mounted) return;
      AppSnackBar.success(context, 'Account created. You are signed in.');
      Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(context, 'Could not create account.');
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
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                AppStrings.createAccountTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppStrings.createAccountSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 28),
              AuthTextField(
                controller: _fullName,
                hintText: AppStrings.fullNameLabel,
                prefixIcon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[AutofillHints.name],
                validator: (String? v) => (v == null || v.trim().isEmpty)
                    ? AppStrings.fullNameRequired
                    : null,
                onFieldSubmitted: (_) => _emailFocus.requestFocus(),
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _email,
                focusNode: _emailFocus,
                hintText: AppStrings.emailLabel,
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[AutofillHints.email],
                validator: _validateEmail,
                onFieldSubmitted: (_) => _usernameFocus.requestFocus(),
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _username,
                focusNode: _usernameFocus,
                hintText: AppStrings.usernameOnlyLabel,
                prefixIcon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[AutofillHints.newUsername],
                validator: (String? v) => (v == null || v.trim().isEmpty)
                    ? AppStrings.usernameFieldRequired
                    : null,
                onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _password,
                focusNode: _passwordFocus,
                hintText: AppStrings.passwordLabel,
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[AutofillHints.newPassword],
                validator: _validatePassword,
                onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
                suffix: _VisibilityToggle(
                  obscured: _obscurePassword,
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: _confirmPassword,
                focusNode: _confirmFocus,
                hintText: AppStrings.confirmPasswordLabel,
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done,
                validator: _validateConfirm,
                onFieldSubmitted: (_) => _onSignUp(),
                suffix: _VisibilityToggle(
                  obscured: _obscureConfirm,
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                label: AppStrings.signUp,
                loading: _submitting,
                onPressed: _onSignUp,
              ),
              const SizedBox(height: 22),
              AuthFooterLink(
                prompt: AppStrings.alreadyHaveAccount,
                linkLabel: AppStrings.signIn,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({required this.obscured, required this.onPressed});

  final bool obscured;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: obscured ? 'Show password' : 'Hide password',
      icon: Icon(
        obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: AppColors.textMuted,
        size: 21,
      ),
    );
  }
}
