import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenPair {
  const TokenPair({required this.access, required this.refresh});
  final String access;
  final String refresh;
}

class TokenStore {
  /// If [memory] is set (e.g. in unit tests), reads/writes use the map instead of the platform keystore.
  TokenStore({FlutterSecureStorage? secure, SharedPreferences? prefsTest, Map<String, String>? memory})
      : _memory = memory,
        _secure = memory != null ? null : (secure ?? const FlutterSecureStorage()),
        _prefsTest = prefsTest;

  static const _kAccess = 'umbraro_access_token';
  static const _kRefresh = 'umbraro_refresh_token';

  static const _legacyAccess = 'access_token';
  static const _legacyRefresh = 'refresh_token';

  final Map<String, String>? _memory;
  final FlutterSecureStorage? _secure;
  final SharedPreferences? _prefsTest;

  Future<TokenPair?> read() async {
    if (_memory != null) {
      final a = _memory![_kAccess];
      final r = _memory![_kRefresh];
      if (a != null && r != null) {
        return TokenPair(access: a, refresh: r);
      }
    } else {
      var access = await _secure!.read(key: _kAccess);
      var refresh = await _secure!.read(key: _kRefresh);
      if (access != null && refresh != null) {
        return TokenPair(access: access, refresh: refresh);
      }
    }
    return _migrateFromLegacy();
  }

  Future<TokenPair?> _migrateFromLegacy() async {
    final prefs = _prefsTest ?? await SharedPreferences.getInstance();
    final a = prefs.getString(_legacyAccess);
    final r = prefs.getString(_legacyRefresh);
    if (a == null || r == null) return null;
    await _writeSecure(a, r);
    if (_prefsTest == null) {
      await prefs.remove(_legacyAccess);
      await prefs.remove(_legacyRefresh);
    } else {
      await _prefsTest!.remove(_legacyAccess);
      await _prefsTest!.remove(_legacyRefresh);
    }
    if (kDebugMode) {
      // ignore: avoid_print
      print('UmbraRo: migrated JWT storage from shared_preferences to secure storage');
    }
    return TokenPair(access: a, refresh: r);
  }

  Future<void> _writeSecure(String access, String refresh) async {
    if (_memory != null) {
      _memory![_kAccess] = access;
      _memory![_kRefresh] = refresh;
    } else {
      await _secure!.write(key: _kAccess, value: access);
      await _secure!.write(key: _kRefresh, value: refresh);
    }
  }

  Future<void> write({required String access, required String refresh}) async {
    await _writeSecure(access, refresh);
  }

  Future<void> clear() async {
    if (_memory != null) {
      _memory!.remove(_kAccess);
      _memory!.remove(_kRefresh);
    } else {
      await _secure!.delete(key: _kAccess);
      await _secure!.delete(key: _kRefresh);
    }
    if (_prefsTest != null) {
      await _prefsTest!.remove(_legacyAccess);
      await _prefsTest!.remove(_legacyRefresh);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyAccess);
    await prefs.remove(_legacyRefresh);
  }
}
