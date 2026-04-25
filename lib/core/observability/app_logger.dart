import 'package:logger/logger.dart';
import 'package:umbraro/core/config/app_config.dart';

class AppLog {
  AppLog._();

  static final Logger _log = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 3,
    ),
  );

  static void d(String m, [Object? e]) {
    if (e != null) {
      _log.d('UmbraRo [${AppConfig.appEnv}] $m: $e');
    } else {
      _log.d('UmbraRo [${AppConfig.appEnv}] $m');
    }
  }

  static void i(String m) => _log.i('UmbraRo [${AppConfig.appEnv}] $m');

  static void w(String m) => _log.w('UmbraRo [${AppConfig.appEnv}] $m');

  static void e(String m, Object? error, [StackTrace? s]) {
    _log.e('UmbraRo [${AppConfig.appEnv}] $m', error: error, stackTrace: s);
  }
}
