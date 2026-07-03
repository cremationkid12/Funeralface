import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:everroute/core/app_flavor.dart';

/// Loads committed `assets/env.default`, then optional `assets/.env` overrides.
/// When the active flavor is [AppFlavor.dev], also loads optional `assets/.env.dev`.
Future<void> loadAppDotenv() async {
  var base = '';
  try {
    base = await rootBundle.loadString('assets/env.default');
  } catch (_) {}

  final overrides = <String>[];
  try {
    final local = await rootBundle.loadString('assets/.env');
    if (local.trim().isNotEmpty) {
      overrides.add(local);
    }
  } catch (_) {}

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

  static String _flavorFallback({required String dev, required String prod}) =>
      parseAppFlavor() == AppFlavor.dev ? dev : prod;

  static String get apiBaseUrl => _afterDefine(
    'API_BASE_URL',
    const String.fromEnvironment('API_BASE_URL', defaultValue: ''),
    _flavorFallback(
      dev: 'http://localhost:8010',
      prod: 'https://funeralface-backend-production.up.railway.app',
    ),
  );

  /// Base URL for family status pages in the browser (no trailing slash).
  static String get familyLinkBaseUrl => _afterDefine(
    'FAMILY_LINK_BASE',
    const String.fromEnvironment('FAMILY_LINK_BASE', defaultValue: ''),
    _flavorFallback(
      dev: 'http://localhost:5173',
      prod: 'https://everroutefuneral.com',
    ),
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

  static const int passwordResetOtpDigits = 8;
}
