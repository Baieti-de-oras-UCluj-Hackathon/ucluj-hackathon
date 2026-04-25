import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:umbraro/core/config/app_config.dart';
import 'package:umbraro/core/observability/app_logger.dart';
import 'package:umbraro/core/services/auth_service.dart';

String teamIdFromName(String? teamName) {
  if (teamName == null || teamName.isEmpty) return 'unknown';
  return teamName
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

class UserProfileSync {
  UserProfileSync({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<void> syncFromAuthUser(AuthUser me, {required String firebaseUid}) async {
    if (!AppConfig.useFirebaseAuth) return;
    try {
      final teamId = teamIdFromName(me.teamName);
      final ref = _db.doc('users/$firebaseUid');
      await ref.set(
        {
          'appUserId': me.id,
          'email': me.email,
          'teamName': me.teamName,
          'teamId': teamId,
          'schemaVersion': 1,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      AppLog.i('UmbraRo metrics: firestore_backfill success uid=$firebaseUid');
    } catch (e) {
      AppLog.w('UmbraRo metrics: firestore_backfill fail: $e');
    }
  }
}
