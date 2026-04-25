import 'api_client.dart';

class AuthUser {
  AuthUser({
    required this.id,
    required this.email,
    this.fullName,
    required this.role,
    required this.teamName,
    required this.isActive,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        fullName: json['full_name']?.toString(),
        role: json['role']?.toString() ?? '',
        teamName: json['team_name'] as String?,
        isActive: json['is_active'] as bool? ?? false,
      );

  final String id;
  final String email;
  final String? fullName;
  final String role;
  final String? teamName;
  final bool isActive;
}

class AuthService {
  AuthService(this._api);

  final ApiClient _api;

  Future<List<String>> fetchTeams() async {
    final list = await _api.getList('/auth/teams');
    return list.cast<String>();
  }

  Future<AuthUser> register({
    required String email,
    required String password,
    required String fullName,
    required String teamName,
  }) async {
    final data = await _api.post('/auth/register', body: {
      'email': email,
      'password': password,
      'full_name': fullName,
      'team_name': teamName,
    });
    return AuthUser.fromJson(data);
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final data = await _api.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    _setTokensFromResponse(data);
  }

  void _setTokensFromResponse(Map<String, dynamic> data) {
    _api.setTokens(
      access: data['access_token'] as String,
      refresh: data['refresh_token'] as String,
    );
  }

  /// Verifies [idToken] on the backend; returns FastAPI access/refresh tokens.
  Future<void> exchangeWithFirebaseIdToken(String idToken) async {
    final data = await _api.post(
      '/auth/firebase',
      firebaseIdToken: idToken,
    );
    _setTokensFromResponse(data);
  }

  /// Creates app user and returns JWT; requires a fresh Firebase [idToken].
  Future<void> registerWithFirebaseIdToken({
    required String idToken,
    required String teamName,
  }) async {
    final data = await _api.post(
      '/auth/register_with_firebase',
      firebaseIdToken: idToken,
      body: {'team_name': teamName},
    );
    _setTokensFromResponse(data);
  }

  Future<void> refresh() async {
    final rt = _api.refreshToken;
    if (rt == null) throw ApiException(401, 'No refresh token');
    final data = await _api.post('/auth/refresh', body: {
      'refresh_token': rt,
    });
    _api.setTokens(
      access: data['access_token'] as String,
      refresh: data['refresh_token'] as String,
    );
  }

  Future<AuthUser> me() async {
    final data = await _api.get('/auth/me');
    return AuthUser.fromJson(data);
  }

  void logout() {
    _api.clearTokens();
  }
}
