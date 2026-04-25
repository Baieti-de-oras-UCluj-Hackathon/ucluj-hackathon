import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:umbraro/core/observability/app_logger.dart';

import 'global_error_reporter_io.dart' if (dart.library.html) 'global_error_reporter_web.dart'
    as impl;

void installGlobalErrorHandlers() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLog.e('flutter', details.exception, details.stack);
    if (!kIsWeb) {
      impl.report(details.exception, details.stack ?? StackTrace.current);
    }
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLog.e('platform', error, stack);
    if (!kIsWeb) {
      impl.report(error, stack);
    }
    return true;
  };
}
