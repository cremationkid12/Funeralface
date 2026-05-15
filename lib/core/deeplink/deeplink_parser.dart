final RegExp _allowedTokenPattern = RegExp(r'^[A-Za-z0-9._~-]{6,256}$');

/// Extracts the family assignment token from a deep link [Uri].
///
/// Strict by default:
/// - allows only `/family/<token>` path shape
/// - requires exact [expectedHost] when provided
/// - rejects malformed/suspicious token values
///
/// Set [allowQueryFallback] to true only for temporary compatibility with
/// legacy links that use `?token=<token>`.
String? extractFamilyAssignmentToken(
  Uri uri, {
  String? expectedHost,
  bool allowQueryFallback = false,
}) {
  if (expectedHost != null &&
      expectedHost.isNotEmpty &&
      uri.host.isNotEmpty &&
      uri.host != expectedHost) {
    return null;
  }

  if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'family') {
    final t = uri.pathSegments[1].trim();
    if (_isAllowedToken(t)) return t;
  }

  if (allowQueryFallback) {
    final q = uri.queryParameters['token']?.trim();
    if (q != null && _isAllowedToken(q)) return q;
  }

  return null;
}

bool _isAllowedToken(String token) {
  if (token.isEmpty) return false;
  if (token.contains('/')) return false;
  if (token.contains('..')) return false;
  return _allowedTokenPattern.hasMatch(token);
}

/// Tokens parsed from the Supabase password recovery redirect
/// (`#access_token=...&refresh_token=...&type=recovery`).
class PasswordRecoveryTokens {
  const PasswordRecoveryTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;
}

PasswordRecoveryTokens? extractPasswordRecoveryTokens(
  Uri uri, {
  String? expectedHost,
}) {
  if ((uri.scheme == 'https' || uri.scheme == 'http') &&
      expectedHost != null &&
      expectedHost.isNotEmpty) {
    if (uri.host.isEmpty || uri.host != expectedHost) return null;
  }

  final p = uri.path;
  final pathOk =
      p == '/auth/reset-password' ||
      p.endsWith('/auth/reset-password') ||
      p == '/reset-password' ||
      p.endsWith('/reset-password');
  if (!pathOk) return null;

  final qp = uri.fragment.isNotEmpty
      ? Uri.splitQueryString(uri.fragment)
      : uri.queryParameters;
  final accessToken = qp['access_token']?.trim() ?? '';
  final refreshToken = qp['refresh_token']?.trim() ?? '';
  if (accessToken.isEmpty || refreshToken.isEmpty) return null;

  final type = qp['type']?.trim().toLowerCase();
  if (type != null && type.isNotEmpty && type != 'recovery') return null;

  return PasswordRecoveryTokens(
    accessToken: accessToken,
    refreshToken: refreshToken,
  );
}
