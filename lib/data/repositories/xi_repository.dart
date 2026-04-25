import '../../core/services/api_client.dart';
import '../models/xi_prediction.dart';

class XiRepository {
  final ApiClient _apiClient;

  XiRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<XiPredictionResponse> predictXi({
    required String formation,
    int? opponentTeamId,
  }) async {
    final response = await _apiClient.post(
      '/xi/predict',
      body: {
        'formation': formation,
        if (opponentTeamId != null) 'opponent_team_id': opponentTeamId,
      },
    );
    return XiPredictionResponse.fromJson(response);
  }
}
