class WeekFixtureDriver {
  final String feature;
  final String label;
  final double importance;
  final String direction;

  WeekFixtureDriver({
    required this.feature,
    required this.label,
    required this.importance,
    required this.direction,
  });

  factory WeekFixtureDriver.fromJson(Map<String, dynamic> j) =>
      WeekFixtureDriver(
        feature: j['feature'] as String? ?? '',
        label: j['label'] as String? ?? '',
        importance: (j['importance'] as num?)?.toDouble() ?? 0,
        direction: j['direction'] as String? ?? 'positive',
      );
}

class WeekFixture {
  final String matchId;
  final String season;
  final String matchDate;
  final String homeTeam;
  final String awayTeam;
  final int? homeScore;
  final int? awayScore;
  final String? venue;
  final double? homeWinProbability;
  final List<WeekFixtureDriver> keyDrivers;
  final List<WeekFixtureDriver> topRisks;
  final String narrative;

  WeekFixture({
    required this.matchId,
    required this.season,
    required this.matchDate,
    required this.homeTeam,
    required this.awayTeam,
    this.homeScore,
    this.awayScore,
    this.venue,
    this.homeWinProbability,
    required this.keyDrivers,
    required this.topRisks,
    required this.narrative,
  });

  bool get isCompleted => homeScore != null && awayScore != null;

  bool get involvesUCluj =>
      homeTeam.toLowerCase().contains('universitatea cluj') ||
      awayTeam.toLowerCase().contains('universitatea cluj') ||
      homeTeam.toLowerCase().contains('u cluj') ||
      awayTeam.toLowerCase().contains('u cluj');

  bool get isUCLujHome =>
      homeTeam.toLowerCase().contains('universitatea cluj') ||
      homeTeam.toLowerCase().contains('u cluj');

  String get displayDate {
    if (matchDate.length >= 10) {
      return matchDate.substring(0, 10);
    }
    return matchDate;
  }

  factory WeekFixture.fromJson(Map<String, dynamic> j) => WeekFixture(
        matchId: j['match_id'] as String? ?? '',
        season: j['season']?.toString() ?? '',
        matchDate: j['match_date'] as String? ?? '',
        homeTeam: j['home_team'] as String? ?? '',
        awayTeam: j['away_team'] as String? ?? '',
        homeScore: (j['home_score'] as num?)?.toInt(),
        awayScore: (j['away_score'] as num?)?.toInt(),
        venue: j['venue'] as String?,
        homeWinProbability:
            (j['home_win_probability'] as num?)?.toDouble(),
        keyDrivers: (j['key_drivers'] as List<dynamic>?)
                ?.map((e) =>
                    WeekFixtureDriver.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        topRisks: (j['top_risks'] as List<dynamic>?)
                ?.map((e) =>
                    WeekFixtureDriver.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        narrative: j['narrative'] as String? ?? '',
      );
}
