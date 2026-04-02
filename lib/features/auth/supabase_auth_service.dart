import 'package:funeralface_mobile/app/session/auth_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  SupabaseAuthService(this._client);

  final SupabaseClient _client;

  Future<void> register({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(email: email.trim(), password: password);
    final session = response.session;
    final user = response.user;
    if (session != null) {
      AuthSession.instance.setSession(
        accessToken: session.accessToken,
        userId: user?.id,
      );
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final session = response.session;
    final user = response.user;
    if (session == null || user == null) {
      throw const AuthException('Login did not return a valid session.');
    }
    AuthSession.instance.setSession(
      accessToken: session.accessToken,
      userId: user.id,
    );
  }

  Future<void> logout() async {
    await _client.auth.signOut();
    AuthSession.instance.clear();
  }
}
