import 'package:flutter/material.dart';

import '../../../core/services/api_client.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_scaffold.dart';

// =============================================================================
// MODEL
// =============================================================================

class _TeamStanding {
  _TeamStanding({
    required this.pos,
    required this.name,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.gf,
    required this.ga,
    required this.gd,
    required this.points,
  });

  final int pos, played, wins, draws, losses, gf, ga, gd, points;
  final String name;

  String get shortName => _nameToShort[name] ?? name;
  String get logoAsset => _nameToLogo[name] ?? '';

  bool isTrackedBy(String? trackedTeam) {
    if (trackedTeam == null) return false;
    final t = trackedTeam.toLowerCase();
    return name.toLowerCase() == t ||
        name.toLowerCase().contains(t) ||
        t.contains(name.toLowerCase()) ||
        shortName.toLowerCase() == t;
  }

  factory _TeamStanding.fromJson(Map<String, dynamic> j, {int fallbackRank = 0}) {
    return _TeamStanding(
      pos: j['position'] as int? ?? fallbackRank,
      name: j['team'] as String? ?? '',
      played: j['played'] as int? ?? 0,
      wins: j['wins'] as int? ?? 0,
      draws: j['draws'] as int? ?? 0,
      losses: j['losses'] as int? ?? 0,
      gf: j['goals_for'] as int? ?? 0,
      ga: j['goals_against'] as int? ?? 0,
      gd: j['goal_difference'] as int? ?? 0,
      points: j['points'] as int? ?? 0,
    );
  }
}

// CSV team name → short display name
const _nameToShort = <String, String>{
  'U Cluj': 'U Cluj',
  'CFR Cluj': 'CFR Cluj',
  'FCSB': 'FCSB',
  'Rapid Bucuresti': 'Rapid',
  'Dinamo Bucuresti': 'Dinamo',
  'Farul Constanta': 'Farul',
  'FC Hermannstadt': 'Hermannstadt',
  'UTA Arad': 'UTA Arad',
  'Petrolul Ploiesti': 'Petrolul',
  'Otelul Galati': 'Oțelul',
  'Csikszereda M. Ciuc': 'Csíkszereda',
  'Unirea Slobozia': 'Unirea',
  'Metaloglobus Bucuresti': 'Metaloglobus',
  'FC Arges': 'FC Argeș',
  'Univ. Craiova': 'U Craiova',
  'FC Botosani': 'FC Botoșani',
};

// CSV team name → local logo asset
const _nameToLogo = <String, String>{
  'U Cluj': 'assets/teams/universitatea_cluj.png',
  'CFR Cluj': 'assets/teams/cfr_cluj.png',
  'FCSB': 'assets/teams/fcsb.png',
  'Rapid Bucuresti': 'assets/teams/rapid_bucuresti.png',
  'Dinamo Bucuresti': 'assets/teams/dinamo_bucuresti.png',
  'Farul Constanta': 'assets/teams/farul_constanta.png',
  'FC Hermannstadt': 'assets/teams/hermannstadt.png',
  'UTA Arad': 'assets/teams/uta_arad.png',
  'Petrolul Ploiesti': 'assets/teams/petrolul_ploiesti.png',
  'Otelul Galati': 'assets/teams/otelul_galati.png',
  'Csikszereda M. Ciuc': 'assets/teams/csikszereda.png',
  'Unirea Slobozia': 'assets/teams/unirea_slobozia.png',
  'Metaloglobus Bucuresti': 'assets/teams/metaloglobus.png',
  'FC Arges': 'assets/teams/arges_pitesti.png',
  'Univ. Craiova': 'assets/teams/universitatea_craiova.png',
  'FC Botosani': 'assets/teams/botosani.png',
};

// =============================================================================
// SCREEN
// =============================================================================

class StandingsScreen extends StatefulWidget {
  const StandingsScreen({
    required this.onTabSelected,
    this.onProfileTap,
    this.trackedTeam,
    this.apiClient,
    super.key,
  });

  final ValueChanged<AppTab> onTabSelected;
  final VoidCallback? onProfileTap;
  final String? trackedTeam;
  final ApiClient? apiClient;

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  List<_TeamStanding> _regular = [];
  bool _loading = true;
  String? _error;

  String? get _team => widget.trackedTeam;

  ApiClient get _api => widget.apiClient ?? ApiClient();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.getList('/standings');
      final standings = list.asMap().entries.map((e) =>
        _TeamStanding.fromJson(e.value as Map<String, dynamic>, fallbackRank: e.key + 1),
      ).toList();
      if (mounted) {
        setState(() {
          _regular = standings;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  _TeamStanding? _findTracked() {
    if (_regular.isEmpty) return null;
    final t = _team;
    if (t == null) {
      // Default: highlight U Cluj
      for (final team in _regular) {
        if (team.name == 'U Cluj') return team;
      }
      return _regular.first;
    }
    for (final team in _regular) {
      if (team.isTrackedBy(t)) return team;
    }
    return _regular.first;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentTab: AppTab.standings,
      onTabSelected: widget.onTabSelected,
      onProfileTap: widget.onProfileTap,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: ColorTokens.accent))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(SpacingTokens.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 40, color: ColorTokens.negative),
                        const SizedBox(height: SpacingTokens.md),
                        Text('Could not load standings',
                            style: TypographyTokens.headline
                                .copyWith(color: ColorTokens.negative)),
                        const SizedBox(height: SpacingTokens.sm),
                        Text(_error!,
                            style: TypographyTokens.body
                                .copyWith(color: ColorTokens.textMuted),
                            textAlign: TextAlign.center),
                        const SizedBox(height: SpacingTokens.lg),
                        TextButton(
                          onPressed: _loadData,
                          child: Text('RETRY',
                              style: TypographyTokens.sectionLabel
                                  .copyWith(color: ColorTokens.accent)),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: ColorTokens.accent,
                  backgroundColor: ColorTokens.surfaceLow,
                  onRefresh: _loadData,
                  child: ListView(
                    children: [
                      const SizedBox(height: SpacingTokens.md),
                      Text('LEAGUE',
                          style: TypographyTokens.displayHero
                              .copyWith(fontSize: 72, height: 0.9)),
                      Text('STANDINGS',
                          style: TypographyTokens.displayHero.copyWith(
                            fontSize: 72,
                            height: 0.9,
                            color: ColorTokens.textMuted.withValues(alpha: 0.18),
                          )),
                      const SizedBox(height: SpacingTokens.md),
                      Text('SUPERLIGA ROMANIA  ·  2024/25',
                          style: TypographyTokens.sectionLabel.copyWith(
                            color: ColorTokens.accent,
                            letterSpacing: 2.0,
                          )),
                      const SizedBox(height: 28),
                      _buildRegularSeason(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildRegularSeason() {
    if (_regular.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(SpacingTokens.xxl),
        color: ColorTokens.surfaceLow,
        child: Column(children: [
          const Icon(Icons.table_chart_outlined, size: 32, color: ColorTokens.textMuted),
          const SizedBox(height: SpacingTokens.md),
          Text('No standings data available.',
              style: TypographyTokens.body.copyWith(color: ColorTokens.textMuted)),
        ]),
      );
    }

    final tracked = _findTracked();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tracked != null) _HeroClubCard(team: tracked),
        const SizedBox(height: 28),
        const _TableHeader(),
        for (final team in _regular)
          _StandingsRow(team: team, trackedTeam: _team),
        if (tracked != null && _regular.isNotEmpty) ...[
          const SizedBox(height: 28),
          _ContextCard(
            label: 'POINTS TO LEADER',
            value: '${_regular.first.points - tracked.points}',
            note: '${_regular.first.shortName} leads with ${_regular.first.points} pts.',
            valueColor: tracked.pos == 1 ? ColorTokens.positive : ColorTokens.negative,
          ),
        ],
        const SizedBox(height: SpacingTokens.xl),
      ],
    );
  }
}

// =============================================================================
// WIDGETS
// =============================================================================

class _HeroClubCard extends StatelessWidget {
  const _HeroClubCard({required this.team});
  final _TeamStanding team;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorTokens.surfaceLow,
      padding: const EdgeInsets.fromLTRB(
        SpacingTokens.lg, SpacingTokens.xl,
        SpacingTokens.lg, SpacingTokens.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (team.logoAsset.isNotEmpty)
              SizedBox(width: 44, height: 44,
                  child: Image.asset(team.logoAsset, fit: BoxFit.contain))
            else
              Container(width: 44, height: 44, color: ColorTokens.surfaceHigh,
                  child: const Icon(Icons.shield_outlined,
                      color: ColorTokens.textMuted, size: 24)),
            const SizedBox(width: SpacingTokens.md),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(team.shortName.toUpperCase(),
                    style: TypographyTokens.headline.copyWith(fontSize: 18)),
                const SizedBox(height: 2),
                Text('YOUR CLUB  ·  SUPERLIGA',
                    style: TypographyTokens.sectionLabel
                        .copyWith(fontSize: 8, letterSpacing: 1.8)),
              ],
            )),
          ]),
          const SizedBox(height: SpacingTokens.xl),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('#${team.pos}', style: TypographyTokens.displayHero.copyWith(
                  fontSize: 64, height: 0.85, color: ColorTokens.accent)),
              const SizedBox(height: 2),
              Text('RANK',
                  style: TypographyTokens.sectionLabel
                      .copyWith(fontSize: 9, letterSpacing: 2.0)),
            ]),
            const SizedBox(width: 32),
            _metric('${team.points}', 'PTS'),
            const SizedBox(width: SpacingTokens.xl),
            _metric('${team.gd > 0 ? "+" : ""}${team.gd}', 'GD'),
            const SizedBox(width: SpacingTokens.xl),
            _metric('${team.wins}-${team.draws}-${team.losses}', 'V-E-Î'),
          ]),
        ],
      ),
    );
  }

  Widget _metric(String value, String label) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value,
          style: TypographyTokens.headline
              .copyWith(fontSize: 22, color: ColorTokens.textPrimary)),
      const SizedBox(height: 2),
      Text(label,
          style: TypographyTokens.sectionLabel
              .copyWith(fontSize: 8, letterSpacing: 1.4)),
    ]);
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final s = TypographyTokens.sectionLabel.copyWith(
      fontSize: 8,
      letterSpacing: 1.0,
      color: ColorTokens.textMuted.withValues(alpha: 0.6),
    );
    return Container(
      color: ColorTokens.surfaceLow,
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.xs),
      child: Row(children: [
        SizedBox(width: 28, child: Text('#', style: s, textAlign: TextAlign.center)),
        const SizedBox(width: 22),
        Expanded(child: Text('CLUB', style: s)),
        SizedBox(width: 26, child: Text('MJ', style: s, textAlign: TextAlign.center)),
        SizedBox(width: 26, child: Text('V', style: s, textAlign: TextAlign.center)),
        SizedBox(width: 26, child: Text('E', style: s, textAlign: TextAlign.center)),
        SizedBox(width: 26, child: Text('Î', style: s, textAlign: TextAlign.center)),
        SizedBox(width: 34, child: Text('DG', style: s, textAlign: TextAlign.center)),
        SizedBox(width: 34, child: Text('PCT', style: s, textAlign: TextAlign.end)),
      ]),
    );
  }
}

class _StandingsRow extends StatelessWidget {
  const _StandingsRow({required this.team, this.trackedTeam});
  final _TeamStanding team;
  final String? trackedTeam;

  bool get _hl {
    if (trackedTeam != null) return team.isTrackedBy(trackedTeam);
    return team.name == 'U Cluj';
  }

  @override
  Widget build(BuildContext context) {
    final hl = _hl;
    final bg = hl ? ColorTokens.surfaceHigh : Colors.transparent;
    final primary = hl ? ColorTokens.accent : ColorTokens.textPrimary;
    final muted = hl
        ? ColorTokens.accent.withValues(alpha: 0.7)
        : ColorTokens.textMuted;

    final nameStyle = TypographyTokens.body.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: primary,
      letterSpacing: hl ? 0.6 : 0,
    );
    final numStyle = TypographyTokens.body.copyWith(
      fontSize: 12,
      color: primary,
      fontWeight: hl ? FontWeight.w700 : FontWeight.w400,
    );

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        SizedBox(
          width: 28,
          child: Text(
            team.pos.toString().padLeft(2, '0'),
            style: numStyle.copyWith(
                color: muted, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
        ),
        if (team.logoAsset.isNotEmpty)
          SizedBox(
              width: 18,
              height: 18,
              child: Image.asset(team.logoAsset, fit: BoxFit.contain))
        else
          SizedBox(
              width: 18,
              height: 18,
              child: Icon(Icons.shield_outlined, size: 14, color: muted)),
        const SizedBox(width: SpacingTokens.xxs),
        Expanded(
            child: Text(team.shortName.toUpperCase(),
                style: nameStyle,
                overflow: TextOverflow.ellipsis)),
        SizedBox(
            width: 26,
            child: Text('${team.played}',
                style: numStyle, textAlign: TextAlign.center)),
        SizedBox(
            width: 26,
            child: Text('${team.wins}',
                style: numStyle, textAlign: TextAlign.center)),
        SizedBox(
            width: 26,
            child: Text('${team.draws}',
                style: numStyle, textAlign: TextAlign.center)),
        SizedBox(
            width: 26,
            child: Text('${team.losses}',
                style: numStyle, textAlign: TextAlign.center)),
        SizedBox(
          width: 34,
          child: Text(
            '${team.gd > 0 ? "+" : ""}${team.gd}',
            style: numStyle.copyWith(
              color: hl
                  ? ColorTokens.accent
                  : team.gd > 0
                      ? ColorTokens.positive
                      : team.gd < 0
                          ? ColorTokens.negative
                          : primary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(
            width: 34,
            child: Text('${team.points}',
                style: numStyle.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.end)),
      ]),
    );
  }
}

class _ContextCard extends StatelessWidget {
  const _ContextCard({
    required this.label,
    required this.value,
    required this.note,
    this.valueColor,
  });

  final String label, value, note;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: ColorTokens.surfaceLow,
      padding: const EdgeInsets.fromLTRB(
        SpacingTokens.lg, SpacingTokens.lg,
        SpacingTokens.lg, SpacingTokens.md,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TypographyTokens.sectionLabel),
        const SizedBox(height: SpacingTokens.xs),
        Text(value,
            style: TypographyTokens.displayHero.copyWith(
                fontSize: 48,
                height: 0.9,
                color: valueColor ?? ColorTokens.accent)),
        const SizedBox(height: SpacingTokens.sm),
        Text(note, style: TypographyTokens.body.copyWith(fontSize: 13)),
      ]),
    );
  }
}
