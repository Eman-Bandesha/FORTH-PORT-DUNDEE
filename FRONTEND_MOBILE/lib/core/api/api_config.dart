import 'dart:io';

import 'package:flutter/foundation.dart';

/// Base URL for the Django REST API (`/api/v1` included).
class ApiConfig {
  ApiConfig._();

  static String? overrideBaseUrl;

  static String get baseUrl {
    if (overrideBaseUrl != null) return overrideBaseUrl!;
    if (kIsWeb) return 'http://127.0.0.1:8000/api/v1';
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://127.0.0.1:8000/api/v1';
  }
}
