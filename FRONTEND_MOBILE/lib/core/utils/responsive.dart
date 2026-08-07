import 'package:flutter/widgets.dart';

/// Lightweight responsive helpers built on top of [MediaQuery].
///
/// These keep layout code readable while ensuring the UI adapts to everything
/// from small/compact phones to large/foldable displays without hardcoding
/// device-specific numbers.
extension ResponsiveContext on BuildContext {
  Size get _screen => MediaQuery.sizeOf(this);

  double get screenWidth => _screen.width;
  double get screenHeight => _screen.height;
  double get shortestSide => _screen.shortestSide;

  /// `true` on tablets / large devices.
  bool get isTablet => shortestSide >= 600;

  /// Scales [size] by the screen width relative to a 390pt reference (iPhone
  /// 13/14 width), clamped so text and artwork never become extreme.
  double scale(double size, {double min = 0.85, double max = 1.25}) {
    final double factor = (screenWidth / 390).clamp(min, max);
    return size * factor;
  }
}
