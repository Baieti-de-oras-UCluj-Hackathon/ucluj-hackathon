import 'package:firebase_crashlytics/firebase_crashlytics.dart';

Future<void> set(String? id) async {
  try {
    await FirebaseCrashlytics.instance.setUserIdentifier(id ?? 'anonymous');
  } catch (_) {}
}
