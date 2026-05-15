import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:everroute/core/app_flavor.dart';

/// Loads `assets/.env` as the base config. When the active flavor is [AppFlavor.dev],
/// also loads optional `assets/.env.dev` (must live under `assets/` in `pubspec.yaml`);
/// dev keys override the base file per `flutter_dotenv` merge rules.
Future<void> loadAppDotenv() async {
  var base = '';
  try {
    base = await rootBundle.loadString('assets/.env');
  } catch (_) {}

  final overrides = <String>[];
  if (parseAppFlavor() == AppFlavor.dev) {
    try {
      final dev = await rootBundle.loadString('assets/.env.dev');
      if (dev.trim().isNotEmpty) {
        overrides.add(dev);
      }
    } catch (_) {}
  }

  dotenv.loadFromString(
    envString: base,
    overrideWith: overrides,
    isOptional: true,
  );
}

/// App configuration from [loadAppDotenv] / `flutter_dotenv`, with non-empty
/// `--dart-define` values taking precedence (CI / release builds).
class AppEnv {
  AppEnv._();

  static String _afterDefine(
    String dotenvKey,
    String defineValue,
    String fallback,
  ) {
    if (defineValue.trim().isNotEmpty) return defineValue.trim();
    if (dotenv.isInitialized) {
      final v = dotenv.env[dotenvKey]?.trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return fallback;
  }

  static String get apiBaseUrl => _afterDefine(
    'API_BASE_URL',
    const String.fromEnvironment('API_BASE_URL', defaultValue: ''),
    'http://localhost:8010',
  );

  static String get deeplinkHost => _afterDefine(
    'DEEPLINK_HOST',
    const String.fromEnvironment('DEEPLINK_HOST', defaultValue: ''),
    'localhost',
  );

  /// Base URL shown when staff copy a family link (no trailing slash).
  /// Must match the verified App Links host in production.
  static String get familyLinkBaseUrl => _afterDefine(
    'FAMILY_LINK_BASE',
    const String.fromEnvironment('FAMILY_LINK_BASE', defaultValue: ''),
    'http://localhost:5173',
  );

  static String familyShareUrlForToken(String token) {
    final base = familyLinkBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    return '$base/family/$token';
  }

  /// Public Terms of Use page (`{FAMILY_LINK_BASE}/terms-of-use`).
  static String get termsOfUseUrl {
    final base = familyLinkBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    return '$base/terms-of-use';
  }

  static String get supabaseUrl => _afterDefine(
    'SUPABASE_URL',
    const String.fromEnvironment('SUPABASE_URL', defaultValue: ''),
    '',
  );

  static String get supabaseAnonKey => _afterDefine(
    'SUPABASE_ANON_KEY',
    const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: ''),
    '',
  );

  /// Google OAuth Web client ID used as `serverClientId` for Android sign-in.
  static String get googleWebClientId => _afterDefine(
    'GOOGLE_WEB_CLIENT_ID',
    const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: ''),
    '',
  );

  static bool get hasSupabaseAuthConfig =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;
}
