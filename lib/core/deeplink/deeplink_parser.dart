/// Extracts the opaque family assignment token from a verified deep link [Uri].
///
/// Supported shapes (after the host matches [expectedHost] when provided):
/// - `https://<host>/family/<token>`
/// - `/<host>/family/<token>` (relative)
/// - `?token=<token>` query fallback
String? extractFamilyAssignmentToken(
  Uri uri, {
  String? expectedHost,
}) {
  if (expectedHost != null &&
      expectedHost.isNotEmpty &&
      uri.host.isNotEmpty &&
      uri.host != expectedHost) {
    return null;
  }

  if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'family') {
    final t = uri.pathSegments[1];
    if (t.isNotEmpty) return t;
  }

  final q = uri.queryParameters['token'];
  if (q != null && q.isNotEmpty) return q;

  return null;
}
