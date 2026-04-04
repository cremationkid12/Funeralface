/// Compile-time configuration from `--dart-define`.
/// Example:
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8010`
class AppEnv {
  AppEnv._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8010',
  );

  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static const String deeplinkHost = String.fromEnvironment(
    'DEEPLINK_HOST',
    defaultValue: 'localhost',
  );

  /// Base URL shown when staff copy a family link (no trailing slash).
  /// Must match the verified App Links host in production.
  static const String familyLinkBaseUrl = String.fromEnvironment(
    'FAMILY_LINK_BASE',
    defaultValue: 'https://links.funeralface.app',
  );

  static String familyShareUrlForToken(String token) {
    final base = familyLinkBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    return '$base/family/$token';
  }

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
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
