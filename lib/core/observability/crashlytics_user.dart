import 'crashlytics_user_impl.dart' if (dart.library.html) 'crashlytics_user_stub.dart' as c;

Future<void> setCrashlyticsAppUserId(String? id) => c.set(id);
