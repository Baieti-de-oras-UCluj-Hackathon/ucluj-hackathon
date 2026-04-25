import '../../core/services/api_client.dart';
import '../models/xi_prediction.dart';

class XiOpponentOption {
  XiOpponentOption({required this.id, required this.name});

  factory XiOpponentOption.fromJson(Map<String, dynamic> json) {
    return XiOpponentOption(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
    );
  }

  final int id;
  final String name;
}

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

  Future<List<XiOpponentOption>> fetchOpponentOptions() async {
    final response = await _apiClient.getList('/xi/opponents');
    return response
        .map((item) => XiOpponentOption.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
