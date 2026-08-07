import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';
import 'token_storage.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Map<String, String> get _jsonHeaders => <String, String>{
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Map<String, String> _authHeaders({bool auth = true}) {
    final Map<String, String> headers = Map<String, String>.from(_jsonHeaders);
    if (auth && TokenStorage.accessToken != null) {
      headers['Authorization'] = 'Bearer ${TokenStorage.accessToken}';
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final String base = ApiConfig.baseUrl;
    final Uri root = Uri.parse(base.endsWith('/') ? base : '$base/');
    final String relative = path.startsWith('/') ? path.substring(1) : path;
    return root.resolve(relative).replace(queryParameters: query);
  }

  Future<dynamic> getDecoded(
    String path, {
    Map<String, String>? query,
    bool auth = true,
  }) async {
    final http.Response response = await _send(
      () => _client.get(_uri(path, query), headers: _authHeaders(auth: auth)),
      auth: auth,
    );
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
    bool auth = true,
  }) async {
    final http.Response response = await _send(
      () => _client.get(_uri(path, query), headers: _authHeaders(auth: auth)),
      auth: auth,
    );
    return _decodeObject(response);
  }

  Future<List<dynamic>> getJsonList(
    String path, {
    Map<String, String>? query,
    bool auth = true,
  }) async {
    final dynamic decoded = await getJson(path, query: query, auth: auth);
    if (decoded is List<dynamic>) return decoded;
  if (decoded is Map<String, dynamic> && decoded['results'] is List) {
      return decoded['results'] as List<dynamic>;
    }
    return <dynamic>[];
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final http.Response response = await _send(
      () => _client.post(
        _uri(path),
        headers: _authHeaders(auth: auth),
        body: jsonEncode(body),
      ),
      auth: auth,
    );
    return _decodeObject(response);
  }

  Future<Map<String, dynamic>> patchJson(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final http.Response response = await _send(
      () => _client.patch(
        _uri(path),
        headers: _authHeaders(auth: auth),
        body: jsonEncode(body),
      ),
      auth: auth,
    );
    return _decodeObject(response);
  }

  Future<void> delete(String path, {bool auth = true}) async {
    await _send(
      () => _client.delete(_uri(path), headers: _authHeaders(auth: auth)),
      auth: auth,
    );
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request, {
    required bool auth,
  }) async {
    http.Response response;
    try {
      response = await request();
    } catch (e) {
      throw ApiException(
        'Cannot reach the server. Check your connection and try again.',
        statusCode: 0,
        body: e.toString(),
      );
    }
    if (auth && response.statusCode == 401 && TokenStorage.refreshToken != null) {
      final bool refreshed = await _tryRefresh();
      if (refreshed) {
        try {
          response = await request();
        } catch (e) {
          throw ApiException(
            'Cannot reach the server. Check your connection and try again.',
            statusCode: 0,
            body: e.toString(),
          );
        }
      }
    }
    if (response.statusCode >= 400) {
      throw ApiException(
        _messageFromBody(response.body) ?? 'Request failed',
        statusCode: response.statusCode,
        body: response.body,
      );
    }
    return response;
  }

  Future<bool> _tryRefresh() async {
    try {
      final http.Response response = await _client.post(
        _uri('auth/token/refresh/'),
        headers: _jsonHeaders,
        body: jsonEncode(<String, String>{
          'refresh': TokenStorage.refreshToken!,
        }),
      );
      if (response.statusCode != 200) return false;
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      final String? access = data['access'] as String?;
      if (access == null) return false;
      final String refresh =
          (data['refresh'] as String?) ?? TokenStorage.refreshToken!;
      await TokenStorage.save(access: access, refresh: refresh);
      return true;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    if (response.body.isEmpty) return <String, dynamic>{};
    final dynamic decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{'data': decoded};
  }

  String? _messageFromBody(String body) {
    try {
      final dynamic decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        if (decoded['detail'] is String) return decoded['detail'] as String;
        final List<dynamic>? nonField =
            decoded['non_field_errors'] as List<dynamic>?;
        if (nonField != null && nonField.isNotEmpty) {
          return nonField.first.toString();
        }
      }
    } catch (_) {}
    return null;
  }
}

final ApiClient apiClient = ApiClient();
