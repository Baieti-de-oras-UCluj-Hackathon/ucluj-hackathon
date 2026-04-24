import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({String? baseUrl})
      : _baseUrl = baseUrl ?? _defaultBaseUrl;

  static const String _defaultBaseUrl = 'http://127.0.0.1:8000/api/v1';
  static const Duration _requestTimeout = Duration(seconds: 15);
  final String _baseUrl;
  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isAuthenticated => _accessToken != null;

  void setTokens({required String access, required String refresh}) {
    _accessToken = access;
    _refreshToken = refresh;
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  Future<Map<String, dynamic>> get(String path) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl$path'),
            headers: _headers,
          )
          .timeout(_requestTimeout);
      return _handle(response);
    } on TimeoutException {
      throw ApiException(408, 'Request timed out. Check backend connection.');
    } catch (e) {
      throw ApiException(0, 'Network error: $e');
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_requestTimeout);
      return _handle(response);
    } on TimeoutException {
      throw ApiException(408, 'Request timed out. Check backend connection.');
    } catch (e) {
      throw ApiException(0, 'Network error: $e');
    }
  }

  Future<List<dynamic>> getList(String path) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl$path'),
            headers: _headers,
          )
          .timeout(_requestTimeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      throw ApiException(response.statusCode, _extractDetail(response.body));
    } on TimeoutException {
      throw ApiException(408, 'Request timed out. Check backend connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(0, 'Network error: $e');
    }
  }

  Map<String, dynamic> _handle(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded as Map<String, dynamic>;
    }
    throw ApiException(response.statusCode, _extractDetail(response.body));
  }

  String _extractDetail(String body) {
    try {
      final map = jsonDecode(body);
      if (map is Map && map.containsKey('detail')) return map['detail'].toString();
    } catch (_) {}
    return body;
  }
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
