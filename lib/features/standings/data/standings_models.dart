/// UmbraRo standings DTOs aligned with
/// `GET /api/v1/admin/sync/data/standings?season_id=...&phase=regular|groups`.

int _toInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value.trim());
    if (parsed != null) return parsed;
  }
  return fallback;
}

String _toString(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  return value.toString();
}

/// One row in a standings table (regular or group phase).
class StandingsRow {
  const StandingsRow({
    required this.rank,
    required this.teamId,
    required this.teamName,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDiff,
    required this.points,
    required this.form,
    this.groupName,
  });

  final int rank;
  final String teamId;
  final String teamName;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDiff;
  final int points;

  /// Raw form string from Sportradar sync (e.g. compact "WWDLW").
  final String form;

  /// Present when row belongs to a named standings group (e.g. Championship Round).
  final String? groupName;

  /// Single-match results in order for UI chips (W / D / L only).
  List<String> get formIndicators {
    final upper = form.toUpperCase().trim();
    if (upper.isEmpty) return const [];

    if (upper.contains(',')) {
      return upper
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.length == 1 && 'WDL'.contains(s))
          .toList();
    }

    return [
      for (var i = 0; i < upper.length; i++)
        if ('WDL'.contains(upper[i])) upper[i],
    ];
  }

  factory StandingsRow.fromJson(
    Map<String, dynamic> json, {
    int? fallbackRank,
  }) {
    final name = _toString(json['team_name']).isNotEmpty
        ? _toString(json['team_name'])
        : _toString(json['team']);

    return StandingsRow(
      rank: _toInt(json['rank'], fallback: fallbackRank ?? 0),
      teamId: _toString(json['team_id']),
      teamName: name,
      played: _toInt(json['played']),
      wins: _toInt(json['w']),
      draws: _toInt(json['d']),
      losses: _toInt(json['l']),
      goalsFor: _toInt(json['gf']),
      goalsAgainst: _toInt(json['ga']),
      goalDiff: _toInt(json['gd']),
      points: _toInt(json['pts']),
      form: _toString(json['form']),
      groupName: () {
        final g = json['group_name'] ?? json['group'];
        final s = _toString(g);
        return s.isEmpty ? null : s;
      }(),
    );
  }

  static List<StandingsRow> listFromJson(List<dynamic>? raw) {
    if (raw == null || raw.isEmpty) return const [];
    return raw.asMap().entries.map((e) {
      final map = e.value;
      if (map is! Map<String, dynamic>) {
        throw FormatException('Standings row must be a JSON object');
      }
      return StandingsRow.fromJson(map, fallbackRank: e.key + 1);
    }).toList();
  }
}

/// Wrapper for `championship_round` / `relegation_round` objects.
class StandingsRoundSection {
  const StandingsRoundSection({
    required this.name,
    required this.count,
    required this.standings,
  });

  final String name;
  final int count;
  final List<StandingsRow> standings;

  factory StandingsRoundSection.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const StandingsRoundSection(name: '', count: 0, standings: []);
    }
    final rows = StandingsRow.listFromJson(json['standings'] as List?);
    return StandingsRoundSection(
      name: _toString(json['name']),
      count: _toInt(json['count'], fallback: rows.length),
      standings: rows,
    );
  }
}

/// `phase=regular` response body.
class StandingsRegularResponse {
  const StandingsRegularResponse({
    required this.phase,
    required this.count,
    required this.standings,
  });

  final String phase;
  final int count;
  final List<StandingsRow> standings;

  factory StandingsRegularResponse.fromJson(Map<String, dynamic> json) {
    final rows = StandingsRow.listFromJson(json['standings'] as List?);
    return StandingsRegularResponse(
      phase: _toString(json['phase']).isEmpty ? 'regular' : _toString(json['phase']),
      count: _toInt(json['count'], fallback: rows.length),
      standings: rows,
    );
  }
}

/// `phase=groups` response body.
class StandingsGroupsResponse {
  const StandingsGroupsResponse({
    required this.phase,
    required this.championshipRound,
    required this.relegationRound,
  });

  final String phase;
  final StandingsRoundSection championshipRound;
  final StandingsRoundSection relegationRound;

  factory StandingsGroupsResponse.fromJson(Map<String, dynamic> json) {
    final cr = json['championship_round'];
    final rr = json['relegation_round'];
    return StandingsGroupsResponse(
      phase: _toString(json['phase']).isEmpty ? 'groups' : _toString(json['phase']),
      championshipRound: StandingsRoundSection.fromJson(
        cr is Map<String, dynamic> ? cr : null,
      ),
      relegationRound: StandingsRoundSection.fromJson(
        rr is Map<String, dynamic> ? rr : null,
      ),
    );
  }
}
