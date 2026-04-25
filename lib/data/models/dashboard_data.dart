class DashboardFixture {
  final String matchId;
  final String season;
  final String matchDate;
  final String homeTeam;
  final String awayTeam;
  final int? homeScore;
  final int? awayScore;
  final String? venue;

  DashboardFixture({
    required this.matchId,
    required this.season,
    required this.matchDate,
    required this.homeTeam,
    required this.awayTeam,
    this.homeScore,
    this.awayScore,
    this.venue,
  });

  bool get isCompleted => homeScore != null && awayScore != null;

  String opponentOf(String myTeam) =>
      homeTeam == myTeam ? awayTeam : homeTeam;

  factory DashboardFixture.fromJson(Map<String, dynamic> j) => DashboardFixture(
        matchId: j['match_id'] as String? ?? '',
        season: j['season']?.toString() ?? '',
        matchDate: j['match_date'] as String? ?? '',
        homeTeam: j['home_team'] as String? ?? '',
        awayTeam: j['away_team'] as String? ?? '',
        homeScore: (j['home_score'] as num?)?.toInt(),
        awayScore: (j['away_score'] as num?)?.toInt(),
        venue: j['venue'] as String?,
      );
}

class DashboardKeyDriver {
  final String label;
  final double importance;
  final String direction;

  DashboardKeyDriver({
    required this.label,
    required this.importance,
    required this.direction,
  });

  factory DashboardKeyDriver.fromJson(Map<String, dynamic> j) =>
      DashboardKeyDriver(
        label: j['label'] as String? ?? j['feature'] as String? ?? '',
        importance: (j['importance'] as num?)?.toDouble() ?? 0,
        direction: j['direction'] as String? ?? 'positive',
      );
}

class DashboardData {
  final DashboardFixture? nextFixture;
  final double? winProbability;
  final List<DashboardKeyDriver> keyDrivers;
  final List<DashboardFixture> recentFixtures;
  final List<DashboardFixture> upcomingFixtures;

  DashboardData({
    this.nextFixture,
    this.winProbability,
    required this.keyDrivers,
    required this.recentFixtures,
    required this.upcomingFixtures,
  });

  factory DashboardData.fromJson(Map<String, dynamic> j) => DashboardData(
        nextFixture: j['next_fixture'] != null
            ? DashboardFixture.fromJson(
                j['next_fixture'] as Map<String, dynamic>)
            : null,
        winProbability: (j['win_probability'] as num?)?.toDouble(),
        keyDrivers: (j['key_drivers'] as List<dynamic>?)
                ?.map((e) =>
                    DashboardKeyDriver.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        recentFixtures: (j['recent_fixtures'] as List<dynamic>?)
                ?.map((e) =>
                    DashboardFixture.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        upcomingFixtures: (j['upcoming_fixtures'] as List<dynamic>?)
                ?.map((e) =>
                    DashboardFixture.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
