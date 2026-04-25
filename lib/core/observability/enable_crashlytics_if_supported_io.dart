import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

Future<void> enableCrashlyticsIfSupported() async {
  if (kIsWeb) return;
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
}
