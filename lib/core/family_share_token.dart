import 'dart:math';

/// Generates an opaque token suitable for `/family/<token>` deep links.
/// Charset matches [deeplink_parser] validation: `[A-Za-z0-9._~-]{6,256}`.
String generateFamilyShareToken({int length = 24}) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._~-';
  final rnd = Random.secure();
  final len = length.clamp(6, 256);
  return String.fromCharCodes(
    Iterable.generate(len, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
  );
}
