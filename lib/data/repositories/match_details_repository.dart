import '../models/match_details.dart';
import '../../core/services/api_client.dart';

class MatchDetailsRepository {
  MatchDetailsRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<MatchDetails> fetchMatchDetails(String matchId) async {
    final encoded = Uri.encodeQueryComponent(matchId);
    final data = await _api.get('/match-details?match_id=$encoded');
    return MatchDetails.fromJson(data);
  }
}
