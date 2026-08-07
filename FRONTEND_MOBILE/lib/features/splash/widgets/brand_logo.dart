import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';

/// The Forth Ports logo presented inside a clean white "badge".
///
/// The source artwork sits on a white canvas, so framing it in a rounded white
/// card (rather than placing it directly on the navy backdrop) keeps the mark
/// crisp and intentional, and gives it gentle elevation against the photo.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, required this.size});

  /// Outer edge length of the square badge, in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    final double radius = size * 0.22;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x4D000000),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Image.asset(
        AppAssets.logo,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        // Graceful fallback if the asset is ever missing.
        errorBuilder: (_, _, _) => const Icon(
          Icons.directions_boat_filled_rounded,
          color: AppColors.navy,
          size: 48,
        ),
      ),
    );
  }
}
