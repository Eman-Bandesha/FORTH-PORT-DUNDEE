import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/api/api_exception.dart';
import '../../shared/widgets/primary_button.dart';
import 'data/auth_repository.dart';
import 'reset_password_screen.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/otp_input.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key, required this.email});

  /// Username or email used for the forgot-password request.
  final String email;

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  static const int _otpLength = 6;

  String _otp = '';
  bool _submitting = false;
  String? _errorText;

  bool get _isComplete => _otp.length == _otpLength;

  Future<void> _onVerify() async {
    FocusScope.of(context).unfocus();
    if (!_isComplete) {
      setState(() => _errorText = AppStrings.otpIncomplete);
      return;
    }
    setState(() {
      _errorText = null;
      _submitting = true;
    });

    try {
      final String resetToken = await AuthRepository.instance.verifyOtp(
        usernameOrEmail: widget.email,
        otp: _otp,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ResetPasswordScreen(resetToken: resetToken),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorText = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorText = AppStrings.otpInvalid;
      });
    }
  }

  Future<void> _onResend() async {
    try {
      final String detail =
          await AuthRepository.instance.forgotPassword(widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(detail)));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AuthScaffold(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const SizedBox(height: 8),
        Text(
          AppStrings.verifyOtpTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the 6-digit code sent to your registered email.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.email,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 28),
        OtpInput(
          length: _otpLength,
          onChanged: (String value) => setState(() {
            _otp = value;
            _errorText = null;
          }),
        ),
        if (_errorText != null) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            _errorText!,
            style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 24),
        PrimaryButton(
          label: AppStrings.verifyOtp,
          loading: _submitting,
          onPressed: _onVerify,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _onResend,
          child: const Text('Resend code'),
        ),
      ],
    );
  }
}
