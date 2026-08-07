import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Application-wide theming.
///
/// A single [ColorScheme]-driven theme keeps Material 3 components consistent
/// and makes it trivial to introduce a dark theme later.
abstract final class AppTheme {
  const AppTheme._();

  /// Status/navigation bar styling for light (white) screens: dark icons so the
  /// clock, battery and notification glyphs are visible against the background.
  static const SystemUiOverlayStyle darkStatusBar = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark, // Android
    statusBarBrightness: Brightness.light, // iOS
    systemNavigationBarColor: AppColors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
  );

  /// Status/navigation bar styling for dark (navy) screens: light icons.
  static const SystemUiOverlayStyle lightStatusBar = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.navyDeep,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static ThemeData get light {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      primary: AppColors.navy,
      secondary: AppColors.red,
      brightness: Brightness.light,
    );

    final ThemeData base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF6F8FB),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: lightStatusBar,
        titleTextStyle: TextStyle(
          color: AppColors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.navy,
        displayColor: AppColors.navy,
      ),
    );
  }
}
