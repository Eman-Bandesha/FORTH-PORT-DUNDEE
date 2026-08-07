import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// A centred "prompt + tappable link" line (e.g. "Already have an account?
/// Sign In"). Wraps gracefully on narrow screens.
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.prompt,
    required this.linkLabel,
    required this.onTap,
  });

  final String prompt;
  final String linkLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text(
          prompt,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            linkLabel,
            style: const TextStyle(
              color: AppColors.link,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
