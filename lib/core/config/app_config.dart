class AppConfig {
  AppConfig._();

  static const String appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'development');

  static const bool useFirebaseAuth = bool.fromEnvironment('USE_FIREBASE_AUTH', defaultValue: false);

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://repeated-century-bug-road.trycloudflare.com/api/v1',
  );
}
