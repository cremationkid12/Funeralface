import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Loads project-root `.env` (Flutter asset; see `pubspec.yaml`) then
/// `assets/env.default`. The parser keeps the first value per key, so user
/// `.env` is concatenated first and bundled defaults only fill missing keys.
Future<void> loadAppDotenv() async {
  final parts = <String>[];
  try {
    parts.add(await rootBundle.loadString('.env'));
  } catch (_) {}
  try {
    parts.add(await rootBundle.loadString('assets/env.default'));
  } catch (_) {}
  dotenv.loadFromString(envString: parts.join('\n'), isOptional: true);
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

  static String get appEnv => _afterDefine(
    'APP_ENV',
    const String.fromEnvironment('APP_ENV', defaultValue: ''),
    'development',
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
    'https://links.funeralface.app',
  );

  static String familyShareUrlForToken(String token) {
    final base = familyLinkBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    return '$base/family/$token';
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

  static bool get hasSupabaseAuthConfig =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  static String get flavor {
    switch (appEnv.toLowerCase()) {
      case 'production':
      case 'prod':
        return 'prod';
      case 'staging':
      case 'stage':
        return 'staging';
      default:
        return 'dev';
    }
  }
}
