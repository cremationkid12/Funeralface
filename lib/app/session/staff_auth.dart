import 'auth_session.dart';

/// Bearer token for authenticated staff API calls.
///
/// Ticket 5 removes the temporary `DEV_AUTH_BEARER_TOKEN` dev-JWT fallback:
/// mobile must rely on the Supabase-backed `AuthSession`.
String? staffBearerToken() {
  return AuthSession.instance.accessToken;
}
