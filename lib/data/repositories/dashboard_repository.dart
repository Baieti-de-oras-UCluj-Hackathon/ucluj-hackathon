import '../../core/services/api_client.dart';
import '../models/dashboard_data.dart';

class DashboardRepository {
  DashboardRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  static const String _trackedTeam = 'U Cluj';

  Future<DashboardData> fetchDashboard() async {
    final encoded = Uri.encodeComponent(_trackedTeam);
    final response = await _apiClient.get('/dashboard?team=$encoded');
    return DashboardData.fromJson(response);
  }
}
