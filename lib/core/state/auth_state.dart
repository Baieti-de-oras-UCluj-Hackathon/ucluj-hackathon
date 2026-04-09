import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';

class AuthState extends ChangeNotifier {
  AuthState({ApiClient? apiClient})
      : api = apiClient ?? ApiClient(),
        _authService = AuthService(apiClient ?? ApiClient()) {
    _tryRestoreSession();
  }

  final ApiClient api;
  late final AuthService _authService;

  AuthUser? _user;
  bool _loading = true;
  String? _error;

  AuthUser? get user => _user;
  bool get loading => _loading;
  bool get isLoggedIn => _user != null;
  String? get error => _error;
  AuthService get authService => _authService;

  Future<void> _tryRestoreSession() async {
    _loading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final access = prefs.getString('access_token');
      final refresh = prefs.getString('refresh_token');
      if (access != null && refresh != null) {
        api.setTokens(access: access, refresh: refresh);
        _user = await _authService.me();
      }
    } catch (_) {
      api.clearTokens();
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    _error = null;
    _loading = true;
    notifyListeners();
    try {
      await _authService.login(email: email, password: password);
      _user = await _authService.me();
      await _persistTokens();
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
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
      await _authService.register(
        email: email,
        password: password,
        teamName: teamName,
      );
      return await login(email: email, password: password);
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _authService.logout();
    _user = null;
    _error = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    notifyListeners();
  }

  Future<void> _persistTokens() async {
    final prefs = await SharedPreferences.getInstance();
    final access = api.accessToken;
    final refresh = api.refreshToken;
    if (access != null) await prefs.setString('access_token', access);
    if (refresh != null) await prefs.setString('refresh_token', refresh);
  }
}
