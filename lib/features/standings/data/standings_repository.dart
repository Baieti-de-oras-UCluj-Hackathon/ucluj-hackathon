import 'dart:convert';

import 'package:http/http.dart' as http;

import 'standings_models.dart';

/// Thrown when the standings HTTP call fails or the body is not valid JSON.
class StandingsRepositoryException implements Exception {
  StandingsRepositoryException(this.message, {this.statusCode, this.cause});

  final String message;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() =>
      'StandingsRepositoryException($statusCode): $message${cause != null ? ' ($cause)' : ''}';
}

/// Fetches normalized standings from admin sync data endpoints (no UI).
class StandingsRepository {
  StandingsRepository({
    http.Client? httpClient,
    String? apiBaseUrl,
  })  : _client = httpClient ?? http.Client(),
        _apiBaseUrl = apiBaseUrl ?? _defaultBaseUrl;

  static const _defaultBaseUrl = 'http://localhost:8000/api/v1';

  final http.Client _client;
  final String _apiBaseUrl;

  Uri _standingsUri(String seasonId, String phase) {
    return Uri.parse('$_apiBaseUrl/admin/sync/data/standings').replace(
      queryParameters: <String, String>{
        'season_id': seasonId,
        'phase': phase,
      },
    );
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StandingsRepositoryException(
        'Request failed',
        statusCode: response.statusCode,
      );
    }
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected JSON object');
      }
      return decoded;
    } catch (e) {
      throw StandingsRepositoryException('Invalid JSON body', cause: e);
    }
  }

  /// `phase=regular` — single Superliga table.
  Future<StandingsRegularResponse> fetchRegularSeason(String seasonId) async {
    final json = await _getJson(_standingsUri(seasonId, 'regular'));
    return StandingsRegularResponse.fromJson(json);
  }

  /// `phase=groups` — championship (playoff) and relegation (playout) tables.
  Future<StandingsGroupsResponse> fetchGroupPhase(String seasonId) async {
    final json = await _getJson(_standingsUri(seasonId, 'groups'));
    return StandingsGroupsResponse.fromJson(json);
  }
}
