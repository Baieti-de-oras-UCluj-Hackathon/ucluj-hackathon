import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void report(Object e, StackTrace s) {
  FirebaseCrashlytics.instance.recordError(e, s, fatal: false);
}
