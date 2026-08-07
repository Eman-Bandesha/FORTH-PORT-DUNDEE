import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists JWT tokens in platform secure storage
/// (Android Keystore / iOS Keychain via flutter_secure_storage).
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
    accessToken = await _secure.read(key: _accessKey);
    refreshToken = await _secure.read(key: _refreshKey);
  }

  static Future<void> save({
    required String access,
    required String refresh,
  }) async {
    accessToken = access;
    refreshToken = refresh;
    await _secure.write(key: _accessKey, value: access);
    await _secure.write(key: _refreshKey, value: refresh);
  }

  static Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
    await _secure.delete(key: _accessKey);
    await _secure.delete(key: _refreshKey);
  }

  static bool get hasAccess =>
      accessToken != null && accessToken!.isNotEmpty;
}
