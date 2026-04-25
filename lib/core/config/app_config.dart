class AppConfig {
  AppConfig._();

  static const String appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'development');

  static const bool useFirebaseAuth = bool.fromEnvironment('USE_FIREBASE_AUTH', defaultValue: false);

  static const String apiBaseUrl = 'https://cylinder-noble-foundation-teaches.trycloudflare.com/api/v1';
}
