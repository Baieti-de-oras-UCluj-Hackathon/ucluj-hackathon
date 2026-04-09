import 'package:flutter/material.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_scaffold.dart';

// =============================================================================
// DEMO DATA
// =============================================================================

class _TeamStanding {
  const _TeamStanding({
    required this.pos,
    required this.shortName,
    required this.logoAsset,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.gd,
    required this.points,
    this.form = const [],
  });

  final int pos, played, wins, draws, losses, gd, points;
  final String shortName, logoAsset;
  final List<String> form;

  bool get isTracked => shortName == 'FCSB';
}

const _kStandings = <_TeamStanding>[
  _TeamStanding(pos: 1, shortName: 'CFR Cluj', logoAsset: 'assets/teams/cfr_cluj.png', played: 28, wins: 18, draws: 5, losses: 5, gd: 24, points: 59, form: ['W','W','W','D','W']),
  _TeamStanding(pos: 2, shortName: 'U Craiova', logoAsset: 'assets/teams/universitatea_craiova.png', played: 28, wins: 17, draws: 6, losses: 5, gd: 21, points: 57, form: ['W','D','W','W','L']),
  _TeamStanding(pos: 3, shortName: 'FCSB', logoAsset: 'assets/teams/fcsb.png', played: 28, wins: 14, draws: 8, losses: 6, gd: 18, points: 50, form: ['W','W','D','W','L']),
  _TeamStanding(pos: 4, shortName: 'Rapid', logoAsset: 'assets/teams/rapid_bucuresti.png', played: 28, wins: 14, draws: 7, losses: 7, gd: 12, points: 49, form: ['L','W','W','D','W']),
  _TeamStanding(pos: 5, shortName: 'U Cluj', logoAsset: 'assets/teams/universitatea_cluj.png', played: 28, wins: 13, draws: 8, losses: 7, gd: 10, points: 47, form: ['D','W','L','W','W']),
  _TeamStanding(pos: 6, shortName: 'Dinamo', logoAsset: 'assets/teams/dinamo_bucuresti.png', played: 28, wins: 12, draws: 9, losses: 7, gd: 8, points: 45, form: ['W','D','D','W','L']),
  _TeamStanding(pos: 7, shortName: 'Farul', logoAsset: 'assets/teams/farul_constanta.png', played: 28, wins: 11, draws: 9, losses: 8, gd: 5, points: 42, form: ['D','L','W','W','D']),
  _TeamStanding(pos: 8, shortName: 'Hermannstadt', logoAsset: 'assets/teams/hermannstadt.png', played: 28, wins: 10, draws: 10, losses: 8, gd: 2, points: 40, form: ['L','D','W','D','W']),
  _TeamStanding(pos: 9, shortName: 'Petrolul', logoAsset: 'assets/teams/petrolul_ploiesti.png', played: 28, wins: 10, draws: 8, losses: 10, gd: -1, points: 38, form: ['W','L','D','L','W']),
  _TeamStanding(pos: 10, shortName: 'Oțelul Galați', logoAsset: 'assets/teams/otelul_galati.png', played: 28, wins: 9, draws: 9, losses: 10, gd: -3, points: 36, form: ['D','W','L','D','L']),
  _TeamStanding(pos: 11, shortName: 'FC Botoșani', logoAsset: 'assets/teams/botosani.png', played: 28, wins: 8, draws: 10, losses: 10, gd: -5, points: 34, form: ['L','D','L','W','D']),
  _TeamStanding(pos: 12, shortName: 'UTA Arad', logoAsset: 'assets/teams/uta_arad.png', played: 28, wins: 8, draws: 8, losses: 12, gd: -8, points: 32, form: ['L','L','W','D','L']),
  _TeamStanding(pos: 13, shortName: 'FK Csíkszereda', logoAsset: 'assets/teams/csikszereda.png', played: 28, wins: 7, draws: 9, losses: 12, gd: -10, points: 30, form: ['D','L','L','W','D']),
  _TeamStanding(pos: 14, shortName: 'FC Argeș', logoAsset: 'assets/teams/arges_pitesti.png', played: 28, wins: 6, draws: 8, losses: 14, gd: -16, points: 26, form: ['L','L','D','L','W']),
  _TeamStanding(pos: 15, shortName: 'Unirea Slobozia', logoAsset: 'assets/teams/unirea_slobozia.png', played: 28, wins: 5, draws: 7, losses: 16, gd: -22, points: 22, form: ['L','D','L','L','L']),
  _TeamStanding(pos: 16, shortName: 'Metaloglobus', logoAsset: 'assets/teams/metaloglobus.png', played: 28, wins: 4, draws: 7, losses: 17, gd: -25, points: 19, form: ['L','L','L','D','L']),
];

// =============================================================================
// SCREEN
// =============================================================================

class StandingsScreen extends StatefulWidget {
  const StandingsScreen({
    required this.onTabSelected,
    this.onProfileTap,
    super.key,
  });

  final ValueChanged<AppTab> onTabSelected;
  final VoidCallback? onProfileTap;

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  int _filterIndex = 0;
  static const _filters = ['FULL TABLE', 'TOP 6', 'BOTTOM 6'];

  List<_TeamStanding> get _filtered {
    switch (_filterIndex) {
      case 1:
        return _kStandings.where((t) => t.pos <= 6).toList();
      case 2:
        return _kStandings.where((t) => t.pos > 10).toList();
      default:
        return _kStandings;
    }
  }

  _TeamStanding get _tracked => _kStandings.firstWhere((t) => t.isTracked);

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentTab: AppTab.standings,
      onTabSelected: widget.onTabSelected,
      onProfileTap: widget.onProfileTap,
      body: ListView(
        children: [
          // ── Title zone ──────────────────────────────────────────
          const SizedBox(height: SpacingTokens.md),
          Text(
            'LEAGUE',
            style: TypographyTokens.displayHero.copyWith(
              fontSize: 72,
              height: 0.9,
            ),
          ),
          Text(
            'STANDINGS',
            style: TypographyTokens.displayHero.copyWith(
              fontSize: 72,
              height: 0.9,
              color: ColorTokens.textMuted.withValues(alpha: 0.18),
            ),
          ),
          const SizedBox(height: SpacingTokens.md),
          Text(
            'SUPERLIGA ROMANIA  ·  2025/26  ·  MW 28',
            style: TypographyTokens.sectionLabel.copyWith(
              color: ColorTokens.accent,
              letterSpacing: 2.0,
            ),
          ),

          const SizedBox(height: 36),

          // ── Hero tracked club ───────────────────────────────────
          _HeroClubCard(team: _tracked),

          const SizedBox(height: 36),

          // ── Filter ──────────────────────────────────────────────
          _SegmentedFilter(
            tabs: _filters,
            selected: _filterIndex,
            onChanged: (i) => setState(() => _filterIndex = i),
          ),

          const SizedBox(height: SpacingTokens.lg),

          // ── Table ───────────────────────────────────────────────
          const _TableHeader(),

          for (final team in _filtered) _StandingsRow(team: team),

          const SizedBox(height: 36),

          // ── Context cards ───────────────────────────────────────
          _ContextCard(
            label: 'POINTS TO LEADER',
            value: '09',
            note: 'CFR Cluj · 59 pts · gap closeable in 3 matchweeks',
            valueColor: ColorTokens.negative,
          ),
          const SizedBox(height: 2),
          const _ContextCard(
            label: 'NEXT FIXTURE',
            value: 'VS CFR CLUJ',
            note: 'Away · Dr. Constantin Rădulescu · Sat 19:30',
            isCompact: true,
          ),
          const SizedBox(height: 2),
          const _ContextCard(
            label: 'EUROPEAN QUALIFICATION',
            value: '03',
            note: 'Holding 3rd. 1-point buffer to 4th-placed Rapid.',
            valueColor: ColorTokens.positive,
          ),
        ],
      ),
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
      height: 32,
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
                    fontSize: 9,
                    letterSpacing: 1.6,
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

// -----------------------------------------------------------------------------

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
          // Identity row
          Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: Image.asset(team.logoAsset, fit: BoxFit.contain),
              ),
              const SizedBox(width: SpacingTokens.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.shortName.toUpperCase(),
                      style: TypographyTokens.headline.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'YOUR CLUB  ·  SUPERLIGA',
                      style: TypographyTokens.sectionLabel.copyWith(fontSize: 8, letterSpacing: 1.8),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: SpacingTokens.xl),

          // Large metrics row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Rank — dominant
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${team.pos}',
                    style: TypographyTokens.displayHero.copyWith(
                      fontSize: 64,
                      height: 0.85,
                      color: ColorTokens.accent,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'RANK',
                    style: TypographyTokens.sectionLabel.copyWith(
                      fontSize: 9,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 32),
              // Secondary metrics
              _metric('${team.points}', 'PTS'),
              const SizedBox(width: SpacingTokens.xl),
              _metric('${team.gd > 0 ? "+" : ""}${team.gd}', 'GD'),
              const SizedBox(width: SpacingTokens.xl),
              _metric('${team.wins}-${team.draws}-${team.losses}', 'W-D-L'),
              const Spacer(),
              // Form
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _formRow(team.form),
                  const SizedBox(height: 4),
                  Text(
                    'LAST 5',
                    style: TypographyTokens.sectionLabel.copyWith(fontSize: 8),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TypographyTokens.headline.copyWith(
            fontSize: 22,
            color: ColorTokens.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TypographyTokens.sectionLabel.copyWith(fontSize: 8, letterSpacing: 1.4),
        ),
      ],
    );
  }

  Widget _formRow(List<String> form) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: form.map((r) {
        final Color c;
        switch (r) {
          case 'W':
            c = ColorTokens.positive;
          case 'D':
            c = ColorTokens.textMuted;
          default:
            c = ColorTokens.negative;
        }
        return Padding(
          padding: const EdgeInsets.only(left: 3),
          child: Container(width: 10, height: 10, color: c),
        );
      }).toList(),
    );
  }
}

// -----------------------------------------------------------------------------

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
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('#', style: s, textAlign: TextAlign.center)),
          const SizedBox(width: 22),
          Expanded(child: Text('CLUB', style: s)),
          SizedBox(width: 26, child: Text('P', style: s, textAlign: TextAlign.center)),
          SizedBox(width: 26, child: Text('W', style: s, textAlign: TextAlign.center)),
          SizedBox(width: 26, child: Text('D', style: s, textAlign: TextAlign.center)),
          SizedBox(width: 26, child: Text('L', style: s, textAlign: TextAlign.center)),
          SizedBox(width: 34, child: Text('GD', style: s, textAlign: TextAlign.center)),
          SizedBox(width: 34, child: Text('PTS', style: s, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------

class _StandingsRow extends StatelessWidget {
  const _StandingsRow({required this.team});
  final _TeamStanding team;

  @override
  Widget build(BuildContext context) {
    final hl = team.isTracked;

    final bg = hl ? ColorTokens.surfaceHigh : Colors.transparent;
    final primary = hl ? ColorTokens.accent : ColorTokens.textPrimary;
    final muted = hl ? ColorTokens.accent.withValues(alpha: 0.7) : ColorTokens.textMuted;

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
      child: Row(
        children: [
          // Position
          SizedBox(
            width: 28,
            child: Text(
              team.pos.toString().padLeft(2, '0'),
              style: numStyle.copyWith(color: muted, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
          ),
          // Crest
          SizedBox(
            width: 18,
            height: 18,
            child: Image.asset(team.logoAsset, fit: BoxFit.contain),
          ),
          const SizedBox(width: SpacingTokens.xxs),
          // Name
          Expanded(child: Text(team.shortName.toUpperCase(), style: nameStyle, overflow: TextOverflow.ellipsis)),
          // Stats
          SizedBox(width: 26, child: Text('${team.played}', style: numStyle, textAlign: TextAlign.center)),
          SizedBox(width: 26, child: Text('${team.wins}', style: numStyle, textAlign: TextAlign.center)),
          SizedBox(width: 26, child: Text('${team.draws}', style: numStyle, textAlign: TextAlign.center)),
          SizedBox(width: 26, child: Text('${team.losses}', style: numStyle, textAlign: TextAlign.center)),
          // GD — colored
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
          // PTS — heaviest
          SizedBox(
            width: 34,
            child: Text(
              '${team.points}',
              style: numStyle.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------

class _ContextCard extends StatelessWidget {
  const _ContextCard({
    required this.label,
    required this.value,
    required this.note,
    this.valueColor,
    this.isCompact = false,
  });

  final String label, value, note;
  final Color? valueColor;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: ColorTokens.surfaceLow,
      padding: const EdgeInsets.fromLTRB(
        SpacingTokens.lg, SpacingTokens.lg,
        SpacingTokens.lg, SpacingTokens.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TypographyTokens.sectionLabel),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            value,
            style: isCompact
                ? TypographyTokens.headline.copyWith(
                    fontSize: 20,
                    color: valueColor ?? ColorTokens.textPrimary,
                  )
                : TypographyTokens.displayHero.copyWith(
                    fontSize: 48,
                    height: 0.9,
                    color: valueColor ?? ColorTokens.accent,
                  ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(
            note,
            style: TypographyTokens.body.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
