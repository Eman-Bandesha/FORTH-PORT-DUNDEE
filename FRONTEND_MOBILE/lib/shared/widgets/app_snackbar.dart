import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// App-wide snackbar helpers.
abstract final class AppSnackBar {
  const AppSnackBar._();

  static const Color _success = Color(0xFF1E8E54);

  /// Shows a green confirmation snackbar (e.g. "Item deleted").
  static void success(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _success,
          duration: const Duration(seconds: 2),
          content: Row(
            children: <Widget>[
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  static void error(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.red,
          content: Text(message),
        ),
      );
  }
}
