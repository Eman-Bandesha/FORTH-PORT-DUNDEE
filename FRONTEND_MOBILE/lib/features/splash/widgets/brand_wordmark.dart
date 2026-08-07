import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';

/// The stacked "FORTH PORTS / DUNDEE" wordmark.
///
/// Mirrors the brand lock-up: white primary line above a bold red place name.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, required this.fontSize});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          AppStrings.brandLineTop,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: fontSize * 0.06,
            height: 1.05,
          ),
        ),
        SizedBox(height: fontSize * 0.12),
        Text(
          AppStrings.brandLineBottom,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.red,
            fontSize: fontSize * 1.08,
            fontWeight: FontWeight.w800,
            letterSpacing: fontSize * 0.12,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}
