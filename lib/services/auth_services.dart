import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:everroute/features/session/auth_session.dart';
import 'package:everroute/core/network/api_client.dart';
import 'package:everroute/core/push/push_notification_coordinator.dart';

Future<void> ensureBackendProvisioned(ApiClient api, String accessToken) async {
  await api.postJson(
    '/v1/auth/ensure-provisioned',
    body: <String, dynamic>{},
    bearerToken: accessToken,
  );
}

Future<void> acceptInvite(
  ApiClient api,
  String accessToken,
  String inviteToken,
) async {
  await api.postJson(
    '/v1/auth/invites/accept',
    body: <String, dynamic>{'invite_token': inviteToken},
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
    String? inviteToken,
  }) async {
    final body = <String, dynamic>{'email': email.trim(), 'password': password};
    if ((inviteToken ?? '').trim().isNotEmpty) {
      body['invite_token'] = inviteToken!.trim();
    }
    final data = await _apiClient.postJson('/v1/auth/login', body: body);
    return _persistAndMap(data);
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    String? inviteToken,
  }) async {
    final body = <String, dynamic>{
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
    };
    if ((inviteToken ?? '').trim().isNotEmpty) {
      body['invite_token'] = inviteToken!.trim();
    }
    final data = await _apiClient.postJson('/v1/auth/register', body: body);
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

  /// Exchanges emailed OTP for tokens. Does **not** persist locally — call
  /// [completePasswordReset] after the user chooses a new password.
  Future<AuthResult> verifyPasswordResetOtp({
    required String email,
    required String token,
  }) async {
    final data = await _apiClient.postJson(
      '/v1/auth/password/otp/verify',
      body: <String, dynamic>{
        'email': email.trim(),
        'token': token.trim().replaceAll(RegExp(r'\s'), ''),
      },
    );
    final userId = data['user_id']?.toString() ?? '';
    final accessToken = data['access_token']?.toString() ?? '';
    final refreshToken = data['refresh_token']?.toString() ?? '';
    if (userId.isEmpty ||
        accessToken.isEmpty ||
        refreshToken.isEmpty) {
      throw StateError(
        'OTP verification response did not contain a complete session.',
      );
    }
    return AuthResult(
      userId: userId,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  Future<AuthResult> completePasswordReset({
    required String accessToken,
    required String refreshToken,
    required String password,
  }) async {
    final data = await _apiClient.postJson(
      '/v1/auth/password/reset-complete',
      body: <String, dynamic>{
        'access_token': accessToken.trim(),
        'refresh_token': refreshToken.trim(),
        'password': password,
      },
    );
    return _persistAndMap(data);
  }

  Future<void> logout() async {
    await PushNotificationCoordinator.instance.unregisterCurrentDevice();
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
