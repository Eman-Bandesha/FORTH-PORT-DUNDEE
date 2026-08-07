import 'package:flutter/foundation.dart';

/// Base URL for the Django REST API (`/api/v1` included).
///
/// Default: live Render API (needs Wi‑Fi / mobile data).
/// Local override:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
class ApiConfig {
  ApiConfig._();

  static const String productionBaseUrl =
      'https://forth-port-dundee.onrender.com/api/v1';

  static String? overrideBaseUrl;

  static String get baseUrl {
    if (overrideBaseUrl != null && overrideBaseUrl!.isNotEmpty) {
      return overrideBaseUrl!;
    }
    const String fromDefine = String.fromEnvironment('API_BASE_URL');
    if (fromDefine.isNotEmpty) return fromDefine;
    return productionBaseUrl;
  }

  static bool get isProductionApi =>
      !kIsWeb && baseUrl.contains('onrender.com') ||
      baseUrl.contains('onrender.com');
}
