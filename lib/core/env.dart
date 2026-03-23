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
}
