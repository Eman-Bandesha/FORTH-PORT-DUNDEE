import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists JWT tokens.
///
/// Mobile uses [FlutterSecureStorage]. Web uses [SharedPreferences] because
/// secure storage is unreliable in Chrome and throws during sign-in.
class TokenStorage {
  TokenStorage._();

  static const String _accessKey = 'auth_access_token';
  static const String _refreshKey = 'auth_refresh_token';

  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static String? accessToken;
  static String? refreshToken;

  static Future<void> load() async {
    if (kIsWeb) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      accessToken = prefs.getString(_accessKey);
      refreshToken = prefs.getString(_refreshKey);
      return;
    }
    accessToken = await _secure.read(key: _accessKey);
    refreshToken = await _secure.read(key: _refreshKey);
  }

  static Future<void> save({
    required String access,
    required String refresh,
  }) async {
    accessToken = access;
    refreshToken = refresh;
    if (kIsWeb) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessKey, access);
      await prefs.setString(_refreshKey, refresh);
      return;
    }
    await _secure.write(key: _accessKey, value: access);
    await _secure.write(key: _refreshKey, value: refresh);
  }

  static Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
    if (kIsWeb) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessKey);
      await prefs.remove(_refreshKey);
      return;
    }
    await _secure.delete(key: _accessKey);
    await _secure.delete(key: _refreshKey);
  }

  static bool get hasAccess =>
      accessToken != null && accessToken!.isNotEmpty;
}
