import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/primary_button.dart';
import 'data/auth_repository.dart';
import 'verify_otp_screen.dart';
import 'widgets/auth_footer_link.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/auth_text_field.dart';

/// Password recovery entry point.
///
/// The user enters their email and is taken to OTP verification where a code is
/// "sent". Replace the simulated request with your password-reset API call.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _identifier = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _identifier.dispose();
    super.dispose();
  }

  String? _validateIdentifier(String? value) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) return 'Enter your username or registered email';
    return null;
  }

  Future<void> _onSendResetLink() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final String detail = await AuthRepository.instance.forgotPassword(
        _identifier.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(detail)));
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              VerifyOtpScreen(email: _identifier.text.trim()),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final String msg = e is Exception ? e.toString() : 'Request failed';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AuthScaffold(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const SizedBox(height: 12),
        const _MailIllustration(),
        const SizedBox(height: 28),
        Text(
          AppStrings.forgotPasswordTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your username or registered work email. '
          'If an active account exists, we will send a verification code.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 30),
        Form(
          key: _formKey,
          child: AuthTextField(
            controller: _identifier,
            hintText: 'Username or email',
            prefixIcon: Icons.person_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const <String>[AutofillHints.username],
            validator: _validateIdentifier,
            onFieldSubmitted: (_) => _onSendResetLink(),
          ),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: AppStrings.sendResetLink,
          loading: _submitting,
          onPressed: _onSendResetLink,
        ),
        const SizedBox(height: 26),
        AuthFooterLink(
          prompt: AppStrings.rememberPasswordPrompt,
          linkLabel: AppStrings.signIn,
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

/// Decorative "email with lock" mark, composed from Material icons so it needs
/// no extra image asset and tints with the brand palette.
class _MailIllustration extends StatelessWidget {
  const _MailIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.06),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          const Icon(
            Icons.mark_email_unread_rounded,
            size: 64,
            color: AppColors.navy,
          ),
          Positioned(
            right: 30,
            bottom: 34,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_rounded,
                size: 14,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
