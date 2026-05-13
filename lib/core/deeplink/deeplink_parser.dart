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
