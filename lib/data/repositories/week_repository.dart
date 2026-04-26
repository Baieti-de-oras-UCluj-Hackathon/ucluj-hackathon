import '../../core/services/api_client.dart';
import '../models/week_fixture.dart';

class WeekRepository {
  WeekRepository({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<WeekFixture>> fetchWeekFixtures({int weekOffset = 0}) async {
    final list = await _api.getList('/week-fixtures?week_offset=$weekOffset');
    return list
        .cast<Map<String, dynamic>>()
        .map(WeekFixture.fromJson)
        .toList();
  }
}
