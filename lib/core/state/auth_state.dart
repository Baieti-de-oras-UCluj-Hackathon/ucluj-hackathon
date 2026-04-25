import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:umbraro/core/config/app_config.dart';
import 'package:umbraro/core/observability/app_logger.dart';
import 'package:umbraro/core/observability/crashlytics_user.dart';
import 'package:umbraro/core/services/api_client.dart' show ApiClient, ApiException;
import 'package:umbraro/core/services/auth_service.dart';
import 'package:umbraro/data/auth/auth_session_repository.dart';

class AuthState extends ChangeNotifier {
  AuthState({
    required this.api,
    required AuthService auth,
    required AuthSessionRepository session,
    bool runSessionRestore = true,
  })  : _auth = auth,
        _session = session {
    if (runSessionRestore) {
      _tryRestoreSession().then((_) {
        if (useFirebaseAuth) _bindFirebaseAuthListener();
      });
    } else {
      _loading = false;
      if (useFirebaseAuth) _bindFirebaseAuthListener();
    }
  }

  final ApiClient api;
  final AuthService _auth;
  final AuthSessionRepository _session;

  StreamSubscription<User?>? _firebaseAuthSub;
  bool _localSignOutInProgress = false;

  AuthUser? _user;
  bool _loading = true;
  String? _error;

  AuthUser? get user => _user;
  bool get loading => _loading;
  bool get isLoggedIn => _user != null;
  String? get error => _error;
  AuthService get authService => _auth;
  bool get useFirebaseAuth => AppConfig.useFirebaseAuth;

  Future<void> _tryRestoreSession() async {
    _loading = true;
    notifyListeners();
    try {
      final r = await _session.restoreColdStart();
      _user = r.user;
    } catch (_) {
      await _session.signOut();
      _user = null;
    }
    _loading = false;
    await _setCrashlyticsUser();
    notifyListeners();
  }

  Future<void> _setCrashlyticsUser() => setCrashlyticsAppUserId(_user?.id);

  void _bindFirebaseAuthListener() {
    if (!useFirebaseAuth) return;
    _firebaseAuthSub?.cancel();
    _firebaseAuthSub = FirebaseAuth.instance.authStateChanges().listen((fbUser) {
      if (fbUser != null) return;
      if (_localSignOutInProgress || _user == null) return;
      AppLog.w('UmbraRo auth: Firebase session ended — clearing app session');
      unawaited(_session.signOut());
      _user = null;
      _error = null;
      unawaited(_setCrashlyticsUser());
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _firebaseAuthSub?.cancel();
    super.dispose();
  }

  Future<bool> login({required String email, required String password}) async {
    _error = null;
    _loading = true;
    notifyListeners();
    try {
      if (useFirebaseAuth) {
        _user = await _session.signInWithFirebase(email, password);
      } else {
        _user = await _session.signInWithEmailPassword(email, password);
      }
      if (_user == null) {
        _error = 'Sign in failed';
        _loading = false;
        notifyListeners();
        return false;
      }
      _loading = false;
      await _setCrashlyticsUser();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String teamName,
  }) async {
    _error = null;
    _loading = true;
    notifyListeners();
    try {
      if (useFirebaseAuth) {
        _user = await _session.signUpWithFirebase(email, password, teamName);
      } else {
        _user = await _session.signUpWithPassword(email, password, teamName);
      }
      if (_user == null) {
        _error = 'Registration failed';
        _loading = false;
        notifyListeners();
        return false;
      }
      _loading = false;
      await _setCrashlyticsUser();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _localSignOutInProgress = true;
    try {
      await _session.signOut();
    } finally {
      _user = null;
      _error = null;
      _localSignOutInProgress = false;
    }
    await _setCrashlyticsUser();
    notifyListeners();
  }
}
