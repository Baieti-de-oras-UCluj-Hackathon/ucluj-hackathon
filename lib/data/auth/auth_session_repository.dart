import 'package:firebase_auth/firebase_auth.dart';
import 'package:umbraro/core/config/app_config.dart';
import 'package:umbraro/core/observability/app_logger.dart';
import 'package:umbraro/core/services/api_client.dart';
import 'package:umbraro/core/services/auth_service.dart';
import 'package:umbraro/core/storage/token_store.dart';
import 'package:umbraro/data/user/user_profile_sync.dart';

class AuthSessionRepository {
  AuthSessionRepository({
    required this.api,
    required this.auth,
    required this.tokenStore,
    UserProfileSync? userProfileSync,
  }) : _userProfile = userProfileSync;

  final ApiClient api;
  final AuthService auth;
  final TokenStore tokenStore;
  final UserProfileSync? _userProfile;

  Future<({AuthUser? user, bool fromFirebase})> restoreColdStart() async {
    if (AppConfig.useFirebaseAuth) {
      final u = FirebaseAuth.instance.currentUser;
      if (u != null) {
        try {
          final id = await u.getIdToken();
          if (id != null) {
            final ok = await _exchangeIdTokenAndPersist(id, source: 'firebase_cold');
            if (ok) {
              final me = await auth.me();
              await _userProfile?.syncFromAuthUser(me, firebaseUid: u.uid);
              return (user: me, fromFirebase: true);
            }
          }
        } on ApiException catch (e) {
          if (e.isNeedsRegistration) {
            await FirebaseAuth.instance.signOut();
            AppLog.w('UmbraRo auth: dropped orphan Firebase session (needs app registration)');
          } else {
            AppLog.w('UmbraRo auth: firebase exchange failed on cold start: $e');
          }
        } catch (e) {
          AppLog.w('UmbraRo auth: firebase cold start: $e');
        }
      }
    }

    final pair = await tokenStore.read();
    if (pair != null) {
      api.setTokens(access: pair.access, refresh: pair.refresh);
      try {
        final me = await auth.me();
        return (user: me, fromFirebase: false);
      } on ApiException catch (e) {
        AppLog.w('UmbraRo auth: token restore /me failed: $e');
        await tokenStore.clear();
        api.clearTokens();
      }
    }
    return (user: null, fromFirebase: false);
  }

  Future<bool> _exchangeIdTokenAndPersist(String idToken, {required String source}) async {
    try {
      await auth.exchangeWithFirebaseIdToken(idToken);
      final access = api.accessToken;
      final refresh = api.refreshToken;
      if (access == null || refresh == null) return false;
      await tokenStore.write(access: access, refresh: refresh);
      AppLog.i('UmbraRo metrics: auth_exchange_success source=$source');
      return true;
    } on ApiException catch (e) {
      AppLog.w('UmbraRo metrics: auth_exchange_failure status=${e.statusCode} source=$source');
      rethrow;
    }
  }

  Future<void> signOut() async {
    auth.logout();
    if (AppConfig.useFirebaseAuth) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        AppLog.w('UmbraRo auth: signOut: $e');
      }
    }
    await tokenStore.clear();
  }

  Future<AuthUser?> signInWithEmailPassword(String email, String password) async {
    await auth.login(email: email, password: password);
    final me = await auth.me();
    final a = api.accessToken;
    final r = api.refreshToken;
    if (a != null && r != null) await tokenStore.write(access: a, refresh: r);
    return me;
  }

  Future<AuthUser?> signInWithFirebase(String email, String password) async {
    final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final u = cred.user;
    if (u == null) return null;
    final id = await u.getIdToken();
    if (id == null) return null;
    try {
      await _exchangeIdTokenAndPersist(id, source: 'login');
    } on ApiException {
      await FirebaseAuth.instance.signOut();
      rethrow;
    }
    final me = await auth.me();
    await _userProfile?.syncFromAuthUser(me, firebaseUid: u.uid);
    return me;
  }

  Future<AuthUser?> signUpWithFirebase(
    String email,
    String password,
    String teamName,
  ) async {
    final userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final u = userCred.user;
    if (u == null) return null;
    final id = await u.getIdToken();
    if (id == null) return null;
    try {
      try {
        await auth.exchangeWithFirebaseIdToken(id);
      } on ApiException catch (e) {
        if (e.isNeedsRegistration) {
          await auth.registerWithFirebaseIdToken(idToken: id, teamName: teamName);
        } else {
          rethrow;
        }
      }
    } catch (e) {
      await u.delete();
      rethrow;
    }
    final a = api.accessToken;
    final r = api.refreshToken;
    if (a != null && r != null) await tokenStore.write(access: a, refresh: r);
    final me = await auth.me();
    await _userProfile?.syncFromAuthUser(me, firebaseUid: u.uid);
    return me;
  }

  Future<AuthUser?> signUpWithPassword(
    String email,
    String password,
    String teamName,
  ) async {
    await auth.register(
      email: email,
      password: password,
      teamName: teamName,
    );
    await auth.login(email: email, password: password);
    final me = await auth.me();
    final a = api.accessToken;
    final r = api.refreshToken;
    if (a != null && r != null) await tokenStore.write(access: a, refresh: r);
    return me;
  }
}
