import 'enable_crashlytics_if_supported_io.dart' if (dart.library.html) 'enable_crashlytics_if_supported_web.dart' as impl;

Future<void> enableCrashlyticsIfSupported() => impl.enableCrashlyticsIfSupported();
