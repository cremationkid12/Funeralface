import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:funeralface_mobile/features/session/auth_session.dart';
import 'package:funeralface_mobile/core/network/api_client.dart';

Future<void> ensureBackendProvisioned(ApiClient api, String accessToken) async {
  await api.postJson(
    '/v1/auth/ensure-provisioned',
    body: <String, dynamic>{},
    bearerToken: accessToken,
  );
}

class AuthResult {
  AuthResult({
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
  });

  final String userId;
  final String accessToken;
  final String refreshToken;
}

class AuthServices {
  AuthServices({
    required ApiClient apiClient,
    FlutterSecureStorage? secureStorage,
  }) : _apiClient = apiClient,
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _keyAccessToken = 'auth_access_token';
  static const _keyRefreshToken = 'auth_refresh_token';
  static const _keyUserId = 'auth_user_id';

  final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage;

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final data = await _apiClient.postJson(
      '/v1/auth/login',
      body: {'email': email.trim(), 'password': password},
    );
    return _persistAndMap(data);
  }

  Future<AuthResult> register({
    required String email,
    required String password,
  }) async {
    final data = await _apiClient.postJson(
      '/v1/auth/register',
      body: {'email': email.trim(), 'password': password},
    );
    return _persistAndMap(data);
  }

  Future<AuthResult> loginWithGoogle({required String idToken}) async {
    final data = await _apiClient.postJson(
      '/v1/auth/login/google',
      body: {'id_token': idToken},
    );
    return _persistAndMap(data);
  }

  Future<void> recoverPassword({required String email}) async {
    await _apiClient.postJson(
      '/v1/auth/password/recover',
      body: {'email': email.trim()},
    );
  }

  Future<void> logout() async {
    final accessToken = await _secureStorage.read(key: _keyAccessToken);
    if (accessToken != null && accessToken.isNotEmpty) {
      try {
        await _apiClient.postJson(
          '/v1/auth/logout',
          body: {'access_token': accessToken},
        );
      } catch (_) {
        // Ignore network/logout API errors and always clear local session.
      }
    }
    await clearSession();
  }

  Future<void> restoreSession() async {
    final accessToken = await _secureStorage.read(key: _keyAccessToken);
    final userId = await _secureStorage.read(key: _keyUserId);
    AuthSession.instance.setSession(accessToken: accessToken, userId: userId);
  }

  Future<void> clearSession() async {
    await _secureStorage.delete(key: _keyAccessToken);
    await _secureStorage.delete(key: _keyRefreshToken);
    await _secureStorage.delete(key: _keyUserId);
    AuthSession.instance.clear();
  }

  Future<AuthResult> _persistAndMap(Map<String, dynamic> data) async {
    final userId = data['user_id']?.toString() ?? '';
    final accessToken = data['access_token']?.toString() ?? '';
    final refreshToken = data['refresh_token']?.toString() ?? '';
    if (userId.isEmpty || accessToken.isEmpty) {
      throw StateError('Auth response did not contain a valid session.');
    }
    await _secureStorage.write(key: _keyAccessToken, value: accessToken);
    await _secureStorage.write(key: _keyRefreshToken, value: refreshToken);
    await _secureStorage.write(key: _keyUserId, value: userId);
    AuthSession.instance.setSession(accessToken: accessToken, userId: userId);
    return AuthResult(
      userId: userId,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}
