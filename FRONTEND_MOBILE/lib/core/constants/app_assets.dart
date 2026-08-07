/// Centralised registry of bundled asset paths.
///
/// Keeping asset paths in one place avoids magic strings scattered across the
/// codebase and makes refactors (renaming/moving files) a single-line change.
abstract final class AppAssets {
  const AppAssets._();

  static const String _images = 'assets/images';

  /// The official Forth Ports Dundee brand logo.
  static const String logo = '$_images/logo.png';

  /// Port/ship photograph used as the splash backdrop.
  static const String splashBackground = '$_images/splash_background.png';

  // Product imagery (dummy catalogue).
  static const String productBrush = '$_images/brush.png';
  static const String productCableTies = '$_images/cable_ties.png';
  static const String productGland = '$_images/gland.png';
  static const String productGloves = '$_images/gloves.png';
  static const String productSprayBottle = '$_images/spray_bottle.png';
}
