/// Compile-time configuration from `--dart-define`.
/// Example:
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000`
class AppEnv {
  AppEnv._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static const String deeplinkHost = String.fromEnvironment(
    'DEEPLINK_HOST',
    defaultValue: 'localhost',
  );

  /// Temporary dev-only auth token for protected endpoints.
  /// Pass with:
  /// --dart-define=DEV_AUTH_BEARER_TOKEN=your-jwt-token
  static const String devAuthBearerToken = String.fromEnvironment(
    'DEV_AUTH_BEARER_TOKEN',
    defaultValue: '',
  );

  static bool get hasDevAuthBearerToken => devAuthBearerToken.trim().isNotEmpty;

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
