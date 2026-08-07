import 'package:flutter/material.dart';

/// Forth Ports Dundee brand palette.
///
/// Colours are derived from the brand logo: a deep maritime navy, a vivid
/// signal red, and a neutral steel grey accent.
abstract final class AppColors {
  const AppColors._();

  /// Primary brand navy (logo background / app background).
  static const Color navy = Color(0xFF0A2240);

  /// Darker navy used for gradient depth at the bottom of the splash.
  static const Color navyDeep = Color(0xFF061528);

  /// Slightly lighter navy used for surfaces/cards.
  static const Color navyLight = Color(0xFF14365F);

  /// Brand signal red ("DUNDEE" wordmark, accents).
  static const Color red = Color(0xFFE1251B);

  /// Neutral steel grey accent (logo lower band).
  static const Color steel = Color(0xFF9AA7A0);

  /// Interactive link / accent blue (used for auth links).
  static const Color link = Color(0xFF2F6BE0);

  /// Page background for light content screens (e.g. login).
  static const Color surface = Color(0xFFFFFFFF);

  /// Subtle fill for input fields.
  static const Color fieldFill = Color(0xFFF7F9FC);

  /// Default input border / hairline divider colour.
  static const Color border = Color(0xFFDFE5EC);

  /// Muted text (subtitles, hints, helper text).
  static const Color textMuted = Color(0xFF6B7787);

  static const Color white = Color(0xFFFFFFFF);

  /// Softer white for secondary text.
  static const Color white70 = Color(0xB3FFFFFF);

  /// Translucent track for the loading progress bar.
  static const Color progressTrack = Color(0x33FFFFFF);
}
