import 'package:funeralface_mobile/core/env.dart';

/// Bearer token for authenticated staff API calls.
/// Dev: [AppEnv.devAuthBearerToken] via `--dart-define`.
/// Production: replace with secure storage + login flow (later phase).
String? staffBearerToken() {
  final t = AppEnv.devAuthBearerToken.trim();
  if (t.isEmpty) return null;
  return t;
}
