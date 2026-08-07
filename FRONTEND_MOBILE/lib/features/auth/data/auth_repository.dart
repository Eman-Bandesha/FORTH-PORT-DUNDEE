import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/api/token_storage.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.department,
    required this.phone,
    this.mustChangePassword = false,
  });

  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String department;
  final String phone;
  final bool mustChangePassword;

  String get displayName {
    final String full = '$firstName $lastName'.trim();
    if (full.isNotEmpty) return full;
    return username;
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> profile =
        json['profile'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return AuthUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      role: profile['role'] as String? ?? json['role'] as String? ?? '',
      department: profile['department'] as String? ?? '',
      phone: profile['phone'] as String? ?? '',
      mustChangePassword: json['must_change_password'] as bool? ??
          profile['must_change_password'] as bool? ??
          false,
    );
  }

  AuthUser copyWith({bool? mustChangePassword}) {
    return AuthUser(
      id: id,
      username: username,
      email: email,
      firstName: firstName,
      lastName: lastName,
      role: role,
      department: department,
      phone: phone,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
    );
  }
}

/// Authentication against `/api/v1/auth/` (staff accounts only — no public signup).
class AuthRepository {
  AuthRepository._();

  static final AuthRepository instance = AuthRepository._();

  static bool mockMode = false;

  AuthUser? currentUser;

  bool get isLoggedIn => mockMode || TokenStorage.hasAccess;

  Future<void> restoreSession() async {
    if (mockMode) return;
    await TokenStorage.load();
    if (!TokenStorage.hasAccess) {
      currentUser = null;
      return;
    }
    try {
      currentUser = await fetchMe();
    } catch (_) {
      await TokenStorage.clear();
      currentUser = null;
    }
  }

  Future<AuthUser> login({
    required String username,
    required String password,
  }) async {
    if (mockMode) {
      currentUser = const AuthUser(
        id: 1,
        username: 'demo',
        email: 'demo@forthports.demo',
        firstName: 'Demo',
        lastName: 'User',
        role: 'Store Staff',
        department: 'Maintenance Team',
        phone: '',
      );
      return currentUser!;
    }
    final Map<String, dynamic> data = await apiClient.postJson(
      'auth/login/',
      <String, String>{'username': username, 'password': password},
      auth: false,
    );
    final Map<String, dynamic> tokens =
        data['tokens'] as Map<String, dynamic>;
    await TokenStorage.save(
      access: tokens['access'] as String,
      refresh: tokens['refresh'] as String,
    );
    currentUser = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
    final bool mustChange = data['must_change_password'] as bool? ??
        currentUser!.mustChangePassword;
    currentUser = currentUser!.copyWith(mustChangePassword: mustChange);
    return currentUser!;
  }

  Future<AuthUser> fetchMe() async {
    final Map<String, dynamic> data = await apiClient.getJson('auth/me/');
    currentUser = AuthUser.fromJson(data);
    return currentUser!;
  }

  Future<String> forgotPassword(String usernameOrEmail) async {
    if (mockMode) return 'If an active account exists, a verification code has been sent.';
    final Map<String, dynamic> data = await apiClient.postJson(
      'auth/password/forgot/',
      <String, String>{'username': usernameOrEmail},
      auth: false,
    );
    return data['detail'] as String? ??
        'If an active account exists, a verification code has been sent.';
  }

  /// Returns a short-lived reset token after a valid OTP.
  Future<String> verifyOtp({
    required String usernameOrEmail,
    required String otp,
  }) async {
    if (mockMode) {
      if (otp != '123456') {
        throw ApiException('Invalid or expired verification code.', statusCode: 400);
      }
      return 'mock-reset-token';
    }
    final Map<String, dynamic> data = await apiClient.postJson(
      'auth/password/verify-otp/',
      <String, String>{
        'username': usernameOrEmail,
        'otp': otp,
      },
      auth: false,
    );
    final String? token = data['reset_token'] as String?;
    if (token == null || token.isEmpty) {
      throw ApiException('Invalid or expired verification code.', statusCode: 400);
    }
    return token;
  }

  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (mockMode) return;
    await apiClient.postJson(
      'auth/password/reset/',
      <String, String>{
        'reset_token': resetToken,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
      auth: false,
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (mockMode) {
      currentUser = currentUser?.copyWith(mustChangePassword: false);
      return;
    }
    final Map<String, dynamic> data = await apiClient.postJson(
      'auth/password/change/',
      <String, String>{
        'current_password': currentPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
    );
    final Map<String, dynamic>? tokens =
        data['tokens'] as Map<String, dynamic>?;
    if (tokens != null) {
      await TokenStorage.save(
        access: tokens['access'] as String,
        refresh: tokens['refresh'] as String,
      );
    }
    if (data['user'] is Map<String, dynamic>) {
      currentUser = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
    } else {
      currentUser = currentUser?.copyWith(mustChangePassword: false);
    }
  }

  Future<void> logout() async {
    if (!mockMode) {
      try {
        await apiClient.postJson(
          'auth/logout/',
          <String, dynamic>{
            if (TokenStorage.refreshToken != null)
              'refresh': TokenStorage.refreshToken,
          },
        );
      } catch (_) {}
      await TokenStorage.clear();
    }
    currentUser = null;
  }
}
