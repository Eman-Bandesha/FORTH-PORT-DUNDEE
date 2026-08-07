import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';

/// Bottom section of the splash: tagline, a live status line, and a smooth
/// determinate progress bar that tracks real bootstrap progress.
class SplashLoadingFooter extends StatelessWidget {
  const SplashLoadingFooter({
    super.key,
    required this.progress,
    required this.statusLabel,
    required this.barWidth,
  });

  /// Current completion ratio (0.0–1.0).
  final double progress;

  /// Short description of the current startup activity.
  final String statusLabel;

  /// Target width of the progress bar.
  final double barWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          AppStrings.tagline,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white70),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              statusLabel,
              style: const TextStyle(
                color: AppColors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _ProgressBar(progress: progress, width: barWidth),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress, required this.width});

  final double progress;
  final double width;

  @override
  Widget build(BuildContext context) {
    const double height = 4;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: <Widget>[
            const ColoredBox(color: AppColors.progressTrack),
            // Smoothly animate towards the latest progress value.
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: progress.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (BuildContext context, double value, _) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[AppColors.red, Color(0xFFFF6A5C)],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
