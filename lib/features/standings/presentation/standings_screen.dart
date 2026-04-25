import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
    required this.teamId,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.gf,
    required this.ga,
    required this.gd,
    required this.points,
    this.form = '',
    this.group = '',
  });

  final int pos, played, wins, draws, losses, gf, ga, gd, points;
  final String name, teamId, form, group;

  String get shortName => _srNameToShort[name] ?? name;
  String get logoAsset => _srNameToLogo[name] ?? '';

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
      pos: j['rank'] as int? ?? fallbackRank,
      name: j['team'] as String? ?? '',
      teamId: j['team_id'] as String? ?? '',
      played: j['played'] as int? ?? 0,
      wins: j['w'] as int? ?? 0,
      draws: j['d'] as int? ?? 0,
      losses: j['l'] as int? ?? 0,
      gf: j['gf'] as int? ?? 0,
      ga: j['ga'] as int? ?? 0,
      gd: j['gd'] as int? ?? 0,
      points: j['pts'] as int? ?? 0,
      form: j['form'] as String? ?? '',
      group: j['group'] as String? ?? '',
    );
  }
}

// Sportradar name → short display name
const _srNameToShort = <String, String>{
  'CS Universitatea Craiova': 'U Craiova',
  'FC Universitatea Cluj': 'U Cluj',
  'FC CFR 1907 Cluj': 'CFR Cluj',
  'FC Dinamo Bucuresti 1948': 'Dinamo',
  'Rapid Bucuresti 1923': 'Rapid',
  'Fotbal Club FCSB': 'FCSB',
  'ACS Champions FC Arges': 'FC Argeș',
  'FC Farul Constanta': 'Farul',
  'FC Botosani': 'FC Botoșani',
  'FC Petrolul Ploiesti': 'Petrolul',
  'ASC Otelul Galati': 'Oțelul Galați',
  'AFK Csikszereda Miercurea Ciuc': 'FK Csíkszereda',
  'AFC Hermannstadt': 'Hermannstadt',
  'FC Uta Arad': 'UTA Arad',
  'FC Unirea 2004 Slobozia': 'Unirea Slobozia',
  'Metaloglobus Bucuresti': 'Metaloglobus',
};

// Sportradar name → local logo asset
const _srNameToLogo = <String, String>{
  'CS Universitatea Craiova': 'assets/teams/universitatea_craiova.png',
  'FC Universitatea Cluj': 'assets/teams/universitatea_cluj.png',
  'FC CFR 1907 Cluj': 'assets/teams/cfr_cluj.png',
  'FC Dinamo Bucuresti 1948': 'assets/teams/dinamo_bucuresti.png',
  'Rapid Bucuresti 1923': 'assets/teams/rapid_bucuresti.png',
  'Fotbal Club FCSB': 'assets/teams/fcsb.png',
  'ACS Champions FC Arges': 'assets/teams/arges_pitesti.png',
  'FC Farul Constanta': 'assets/teams/farul_constanta.png',
  'FC Botosani': 'assets/teams/botosani.png',
  'FC Petrolul Ploiesti': 'assets/teams/petrolul_ploiesti.png',
  'ASC Otelul Galati': 'assets/teams/otelul_galati.png',
  'AFK Csikszereda Miercurea Ciuc': 'assets/teams/csikszereda.png',
  'AFC Hermannstadt': 'assets/teams/hermannstadt.png',
  'FC Uta Arad': 'assets/teams/uta_arad.png',
  'FC Unirea 2004 Slobozia': 'assets/teams/unirea_slobozia.png',
  'Metaloglobus Bucuresti': 'assets/teams/metaloglobus.png',
};

// =============================================================================
// API
// =============================================================================

const _kBaseUrl = 'http://localhost:8000/api/v1/admin/sync/data';
const _kSeasonId = 'sr:season:131507';

Future<List<_TeamStanding>> _fetchRegular() async {
  final uri = Uri.parse('$_kBaseUrl/standings?season_id=$_kSeasonId&phase=regular');
  final resp = await http.get(uri);
  if (resp.statusCode != 200) return [];
  final data = jsonDecode(resp.body) as Map<String, dynamic>;
  final list = data['standings'] as List? ?? [];
  return list.asMap().entries.map((e) =>
    _TeamStanding.fromJson(e.value as Map<String, dynamic>, fallbackRank: e.key + 1),
  ).toList();
}

Future<({List<_TeamStanding> championship, List<_TeamStanding> relegation})> _fetchGroups() async {
  final uri = Uri.parse('$_kBaseUrl/standings?season_id=$_kSeasonId&phase=groups');
  final resp = await http.get(uri);
  if (resp.statusCode != 200) {
    return (championship: <_TeamStanding>[], relegation: <_TeamStanding>[]);
  }
  final data = jsonDecode(resp.body) as Map<String, dynamic>;

  final crMap = data['championship_round'] as Map<String, dynamic>?;
  final rrMap = data['relegation_round'] as Map<String, dynamic>?;
  final crRaw = (crMap?['standings'] as List?) ?? [];
  final rrRaw = (rrMap?['standings'] as List?) ?? [];

  return (
    championship: crRaw.asMap().entries.map((e) =>
      _TeamStanding.fromJson(e.value as Map<String, dynamic>, fallbackRank: e.key + 1),
    ).toList(),
    relegation: rrRaw.asMap().entries.map((e) =>
      _TeamStanding.fromJson(e.value as Map<String, dynamic>, fallbackRank: e.key + 1),
    ).toList(),
  );
}

// =============================================================================
// SCREEN
// =============================================================================

class StandingsScreen extends StatefulWidget {
  const StandingsScreen({
    required this.onTabSelected,
    this.onProfileTap,
    this.trackedTeam,
    super.key,
  });

  final ValueChanged<AppTab> onTabSelected;
  final VoidCallback? onProfileTap;
  final String? trackedTeam;

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  int _phaseIndex = 0;
  static const _phases = ['SEZON REGULAT', 'FAZA GRUPELOR'];

  List<_TeamStanding> _regular = [];
  List<_TeamStanding> _championship = [];
  List<_TeamStanding> _relegation = [];
  bool _loading = true;

  String? get _team => widget.trackedTeam;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final regular = await _fetchRegular();
      final groups = await _fetchGroups();
      if (mounted) {
        setState(() {
          _regular = regular;
          _championship = groups.championship;
          _relegation = groups.relegation;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  _TeamStanding? _findTracked(List<_TeamStanding> data) {
    if (data.isEmpty) return null;
    final t = _team;
    if (t == null) return data.first;
    for (final team in data) {
      if (team.isTrackedBy(t)) return team;
    }
    return data.first;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentTab: AppTab.standings,
      onTabSelected: widget.onTabSelected,
      onProfileTap: widget.onProfileTap,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: ColorTokens.accent))
          : RefreshIndicator(
              color: ColorTokens.accent,
              backgroundColor: ColorTokens.surfaceLow,
              onRefresh: _loadData,
              child: ListView(
                children: [
                  const SizedBox(height: SpacingTokens.md),
                  Text('LEAGUE',
                      style: TypographyTokens.displayHero.copyWith(fontSize: 72, height: 0.9)),
                  Text('STANDINGS',
                      style: TypographyTokens.displayHero.copyWith(
                        fontSize: 72, height: 0.9,
                        color: ColorTokens.textMuted.withValues(alpha: 0.18),
                      )),
                  const SizedBox(height: SpacingTokens.md),
                  Text('SUPERLIGA ROMANIA  ·  2025/26',
                      style: TypographyTokens.sectionLabel.copyWith(
                        color: ColorTokens.accent, letterSpacing: 2.0,
                      )),
                  const SizedBox(height: 28),
                  _SegmentedFilter(
                    tabs: _phases,
                    selected: _phaseIndex,
                    onChanged: (i) => setState(() => _phaseIndex = i),
                  ),
                  const SizedBox(height: 28),
                  if (_phaseIndex == 0) _buildRegularSeason(),
                  if (_phaseIndex == 1) _buildGroupPhase(),
                ],
              ),
            ),
    );
  }

  Widget _buildRegularSeason() {
    if (_regular.isEmpty) {
      return _emptyState('No regular season data synced yet.');
    }
    final tracked = _findTracked(_regular);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tracked != null) _HeroClubCard(team: tracked),
        const SizedBox(height: 28),
        const _TableHeader(),
        for (final team in _regular)
          _StandingsRow(team: team, trackedTeam: _team),
        if (tracked != null) ...[
          const SizedBox(height: 28),
          _ContextCard(
            label: 'POINTS TO LEADER',
            value: '${_regular.first.points - tracked.points}',
            note: '${_regular.first.shortName} leads with ${_regular.first.points} pts.',
            valueColor: tracked.pos == 1 ? ColorTokens.positive : ColorTokens.negative,
          ),
        ],
      ],
    );
  }

  Widget _buildGroupPhase() {
    if (_championship.isEmpty && _relegation.isEmpty) {
      return _emptyState('No group phase data synced yet.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_championship.isNotEmpty) ...[
          _GroupBanner(
            label: 'CHAMPIONSHIP ROUND  ·  PLAYOFF',
            count: _championship.length,
            accentColor: ColorTokens.accent,
          ),
          const SizedBox(height: SpacingTokens.md),
          const _TableHeader(),
          for (final team in _championship)
            _StandingsRow(team: team, trackedTeam: _team),
        ],
        if (_championship.isNotEmpty && _relegation.isNotEmpty)
          const SizedBox(height: 36),
        if (_relegation.isNotEmpty) ...[
          _GroupBanner(
            label: 'RELEGATION ROUND  ·  PLAYOUT',
            count: _relegation.length,
            accentColor: ColorTokens.negative,
          ),
          const SizedBox(height: SpacingTokens.md),
          const _TableHeader(),
          for (final team in _relegation)
            _StandingsRow(team: team, trackedTeam: _team),
        ],
      ],
    );
  }

  Widget _emptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SpacingTokens.xxl),
      color: ColorTokens.surfaceLow,
      child: Column(children: [
        const Icon(Icons.sync_outlined, size: 32, color: ColorTokens.textMuted),
        const SizedBox(height: SpacingTokens.md),
        Text(message, style: TypographyTokens.body.copyWith(color: ColorTokens.textMuted)),
        const SizedBox(height: SpacingTokens.xs),
        Text('Run standings sync from the admin panel.',
            style: TypographyTokens.sectionLabel),
      ]),
    );
  }
}

// =============================================================================
// WIDGETS
// =============================================================================

class _SegmentedFilter extends StatelessWidget {
  const _SegmentedFilter({
    required this.tabs,
    required this.selected,
    required this.onChanged,
  });

  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = selected == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: Container(
                alignment: Alignment.center,
                color: active ? ColorTokens.surfaceHigh : ColorTokens.surfaceLow,
                child: Text(
                  tabs[i],
                  style: TypographyTokens.sectionLabel.copyWith(
                    color: active ? ColorTokens.accent : ColorTokens.textMuted,
                    fontSize: 10, letterSpacing: 1.6,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _GroupBanner extends StatelessWidget {
  const _GroupBanner({
    required this.label,
    required this.count,
    required this.accentColor,
  });

  final String label;
  final int count;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: SpacingTokens.sm, horizontal: SpacingTokens.md,
      ),
      color: ColorTokens.surfaceLow,
      child: Row(children: [
        Container(width: 3, height: 20, color: accentColor),
        const SizedBox(width: SpacingTokens.sm),
        Text(label,
            style: TypographyTokens.sectionLabel.copyWith(
              color: accentColor, letterSpacing: 2.0,
            )),
        const Spacer(),
        Text('$count TEAMS',
            style: TypographyTokens.sectionLabel.copyWith(fontSize: 9)),
      ]),
    );
  }
}

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
                  child: const Icon(Icons.shield_outlined, color: ColorTokens.textMuted, size: 24)),
            const SizedBox(width: SpacingTokens.md),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(team.shortName.toUpperCase(),
                    style: TypographyTokens.headline.copyWith(fontSize: 18)),
                const SizedBox(height: 2),
                Text('YOUR CLUB  ·  SUPERLIGA',
                    style: TypographyTokens.sectionLabel.copyWith(fontSize: 8, letterSpacing: 1.8)),
              ],
            )),
          ]),
          const SizedBox(height: SpacingTokens.xl),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('#${team.pos}', style: TypographyTokens.displayHero.copyWith(
                  fontSize: 64, height: 0.85, color: ColorTokens.accent)),
              const SizedBox(height: 2),
              Text('RANK', style: TypographyTokens.sectionLabel.copyWith(fontSize: 9, letterSpacing: 2.0)),
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
      Text(value, style: TypographyTokens.headline.copyWith(fontSize: 22, color: ColorTokens.textPrimary)),
      const SizedBox(height: 2),
      Text(label, style: TypographyTokens.sectionLabel.copyWith(fontSize: 8, letterSpacing: 1.4)),
    ]);
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final s = TypographyTokens.sectionLabel.copyWith(
      fontSize: 8, letterSpacing: 1.0,
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

  @override
  Widget build(BuildContext context) {
    final hl = team.isTrackedBy(trackedTeam);
    final bg = hl ? ColorTokens.surfaceHigh : Colors.transparent;
    final primary = hl ? ColorTokens.accent : ColorTokens.textPrimary;
    final muted = hl ? ColorTokens.accent.withValues(alpha: 0.7) : ColorTokens.textMuted;

    final nameStyle = TypographyTokens.body.copyWith(
      fontSize: 12, fontWeight: FontWeight.w700, color: primary,
      letterSpacing: hl ? 0.6 : 0,
    );
    final numStyle = TypographyTokens.body.copyWith(
      fontSize: 12, color: primary, fontWeight: hl ? FontWeight.w700 : FontWeight.w400,
    );

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        SizedBox(width: 28, child: Text(
          team.pos.toString().padLeft(2, '0'),
          style: numStyle.copyWith(color: muted, fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        )),
        if (team.logoAsset.isNotEmpty)
          SizedBox(width: 18, height: 18,
              child: Image.asset(team.logoAsset, fit: BoxFit.contain))
        else
          SizedBox(width: 18, height: 18,
              child: Icon(Icons.shield_outlined, size: 14, color: muted)),
        const SizedBox(width: SpacingTokens.xxs),
        Expanded(child: Text(team.shortName.toUpperCase(), style: nameStyle,
            overflow: TextOverflow.ellipsis)),
        SizedBox(width: 26, child: Text('${team.played}', style: numStyle, textAlign: TextAlign.center)),
        SizedBox(width: 26, child: Text('${team.wins}', style: numStyle, textAlign: TextAlign.center)),
        SizedBox(width: 26, child: Text('${team.draws}', style: numStyle, textAlign: TextAlign.center)),
        SizedBox(width: 26, child: Text('${team.losses}', style: numStyle, textAlign: TextAlign.center)),
        SizedBox(width: 34, child: Text(
          '${team.gd > 0 ? "+" : ""}${team.gd}',
          style: numStyle.copyWith(
            color: hl ? ColorTokens.accent
                : team.gd > 0 ? ColorTokens.positive
                : team.gd < 0 ? ColorTokens.negative : primary,
          ),
          textAlign: TextAlign.center,
        )),
        SizedBox(width: 34, child: Text('${team.points}',
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
        Text(value, style: TypographyTokens.displayHero.copyWith(
            fontSize: 48, height: 0.9, color: valueColor ?? ColorTokens.accent)),
        const SizedBox(height: SpacingTokens.sm),
        Text(note, style: TypographyTokens.body.copyWith(fontSize: 13)),
      ]),
    );
  }
}
