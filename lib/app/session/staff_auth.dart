import 'package:funeralface_mobile/core/env.dart';
import 'auth_session.dart';

/// Bearer token for authenticated staff API calls.
/// Dev: [AppEnv.devAuthBearerToken] via `--dart-define`.
/// Production: replace with secure storage + login flow (later phase).
String? staffBearerToken() {
  final dev = AppEnv.devAuthBearerToken.trim();
  if (dev.isNotEmpty) return dev;
  return AuthSession.instance.accessToken;
}
