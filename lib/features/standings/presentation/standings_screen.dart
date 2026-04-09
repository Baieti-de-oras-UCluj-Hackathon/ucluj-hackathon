import 'package:flutter/material.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_scaffold.dart';

// =============================================================================
// DEMO STANDINGS DATA
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
// STANDINGS SCREEN
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

  _TeamStanding get _tracked =>
      _kStandings.firstWhere((t) => t.isTracked);

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentTab: AppTab.standings,
      onTabSelected: widget.onTabSelected,
      onProfileTap: widget.onProfileTap,
      body: ListView(
        children: [
          // 1 — Title
          Text(
            'COMPETITION / SUPERLIGA',
            style: TypographyTokens.sectionLabel.copyWith(
              color: ColorTokens.accent,
            ),
          ),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            'LEAGUE',
            style: TypographyTokens.displayHero.copyWith(fontSize: 56),
          ),
          Text(
            'STANDINGS',
            style: TypographyTokens.displayHero.copyWith(
              fontSize: 56,
              color: ColorTokens.surfaceHigh,
            ),
          ),
          const SizedBox(height: SpacingTokens.xxs),
          Text(
            'SUPERLIGA ROMANIA · 2024/25  ·  MATCHWEEK 28',
            style: TypographyTokens.sectionLabel,
          ),

          const SizedBox(height: SpacingTokens.xl),

          // 2 — Filter
          _SegmentedFilter(
            tabs: _filters,
            selected: _filterIndex,
            onChanged: (i) => setState(() => _filterIndex = i),
          ),

          const SizedBox(height: SpacingTokens.xl),

          // 3 — Hero club card
          _HeroClubCard(team: _tracked),

          const SizedBox(height: SpacingTokens.xl),

          // 4 — Table header
          const _TableHeader(),
          const Divider(height: 1, color: ColorTokens.divider),

          // 5 — Standings rows
          for (final team in _filtered) _StandingsRow(team: team),

          const SizedBox(height: SpacingTokens.xl),

          // 6 — Summary cards
          _SummaryCard(
            label: 'POINTS TO LEADER',
            value: '09',
            description: 'CFR Cluj leads with 59 pts. Gap closeable in 3 matchweeks.',
            valueColor: ColorTokens.negative,
          ),
          const SizedBox(height: 1),
          const _SummaryCard(
            label: 'NEXT FIXTURE',
            value: 'vs CFR',
            description: 'Home · Dr. Constantin Rădulescu · Sat 19:30',
            isTextValue: true,
          ),
          const SizedBox(height: 1),
          const _SummaryCard(
            label: 'EUROPEAN SPOT',
            value: '03',
            description: 'Currently in European qualification position. 1 point buffer to 4th.',
            valueColor: ColorTokens.positive,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// REUSABLE WIDGETS
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
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: ColorTokens.surfaceLow,
        border: Border.all(color: ColorTokens.divider),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = selected == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? ColorTokens.surfaceHigh : Colors.transparent,
                  border: active
                      ? const Border(
                          bottom: BorderSide(color: ColorTokens.accent, width: 2),
                        )
                      : null,
                ),
                child: Text(
                  tabs[i],
                  style: TypographyTokens.sectionLabel.copyWith(
                    color: active ? ColorTokens.accent : ColorTokens.textMuted,
                    fontSize: 10,
                    letterSpacing: 1.4,
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
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: Image.asset(team.logoAsset, fit: BoxFit.contain),
              ),
              const SizedBox(width: SpacingTokens.sm),
              Text(
                team.shortName.toUpperCase(),
                style: TypographyTokens.headline.copyWith(fontSize: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.sm,
                  vertical: SpacingTokens.xxs,
                ),
                color: ColorTokens.surfaceHigh,
                child: Text(
                  'RANK #${team.pos}',
                  style: TypographyTokens.sectionLabel.copyWith(
                    color: ColorTokens.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.lg),
          Row(
            children: [
              _heroMetric('${team.points}', 'PTS'),
              const SizedBox(width: SpacingTokens.xl),
              _heroMetric(
                '${team.gd > 0 ? '+' : ''}${team.gd}',
                'GD',
              ),
              const SizedBox(width: SpacingTokens.xl),
              _heroMetric('${team.played}', 'P'),
              const SizedBox(width: SpacingTokens.xl),
              _heroMetric('${team.wins}', 'W'),
              const Spacer(),
              _buildForm(team.form),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroMetric(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TypographyTokens.headline.copyWith(
            fontSize: 26,
            color: ColorTokens.accent,
          ),
        ),
        Text(label, style: TypographyTokens.sectionLabel.copyWith(fontSize: 9)),
      ],
    );
  }

  Widget _buildForm(List<String> form) {
    return Row(
      children: form.map((r) {
        Color c;
        switch (r) {
          case 'W':
            c = ColorTokens.positive;
            break;
          case 'D':
            c = ColorTokens.textMuted;
            break;
          default:
            c = ColorTokens.negative;
        }
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Container(width: 8, height: 8, color: c),
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
    final s = TypographyTokens.sectionLabel.copyWith(fontSize: 9);
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: SpacingTokens.xs,
        horizontal: SpacingTokens.xxs,
      ),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('#', style: s)),
          const SizedBox(width: 24),
          Expanded(child: Text('CLUB', style: s)),
          SizedBox(width: 28, child: Text('P', style: s, textAlign: TextAlign.center)),
          SizedBox(width: 28, child: Text('W', style: s, textAlign: TextAlign.center)),
          SizedBox(width: 28, child: Text('D', style: s, textAlign: TextAlign.center)),
          SizedBox(width: 28, child: Text('L', style: s, textAlign: TextAlign.center)),
          SizedBox(width: 36, child: Text('GD', style: s, textAlign: TextAlign.center)),
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
    final highlighted = team.isTracked;
    final bgColor = highlighted ? ColorTokens.surfaceHigh : Colors.transparent;
    final textColor = highlighted ? ColorTokens.accent : ColorTokens.textPrimary;
    final valStyle = TypographyTokens.body.copyWith(
      fontSize: 13,
      color: textColor,
      fontWeight: highlighted ? FontWeight.w700 : FontWeight.w400,
    );

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(
        vertical: SpacingTokens.sm,
        horizontal: SpacingTokens.xxs,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              team.pos.toString().padLeft(2, '0'),
              style: valStyle.copyWith(
                color: highlighted ? ColorTokens.accent : ColorTokens.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 20,
            height: 20,
            child: Image.asset(team.logoAsset, fit: BoxFit.contain),
          ),
          const SizedBox(width: SpacingTokens.xxs),
          Expanded(
            child: Text(
              team.shortName.toUpperCase(),
              style: valStyle.copyWith(fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 28, child: Text('${team.played}', style: valStyle, textAlign: TextAlign.center)),
          SizedBox(width: 28, child: Text('${team.wins}', style: valStyle, textAlign: TextAlign.center)),
          SizedBox(width: 28, child: Text('${team.draws}', style: valStyle, textAlign: TextAlign.center)),
          SizedBox(width: 28, child: Text('${team.losses}', style: valStyle, textAlign: TextAlign.center)),
          SizedBox(
            width: 36,
            child: Text(
              '${team.gd > 0 ? '+' : ''}${team.gd}',
              style: valStyle.copyWith(
                color: team.gd > 0
                    ? ColorTokens.positive
                    : team.gd < 0
                        ? ColorTokens.negative
                        : textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 34,
            child: Text(
              '${team.points}',
              style: valStyle.copyWith(
                fontWeight: FontWeight.w800,
                color: highlighted ? ColorTokens.accent : ColorTokens.textPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.description,
    this.valueColor,
    this.isTextValue = false,
  });

  final String label, value, description;
  final Color? valueColor;
  final bool isTextValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: ColorTokens.surfaceLow,
      padding: const EdgeInsets.all(SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TypographyTokens.sectionLabel),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            value,
            style: isTextValue
                ? TypographyTokens.headline.copyWith(
                    fontSize: 22,
                    color: valueColor ?? ColorTokens.textPrimary,
                  )
                : TypographyTokens.displayHero.copyWith(
                    fontSize: 44,
                    color: valueColor ?? ColorTokens.accent,
                  ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Text(description, style: TypographyTokens.body),
        ],
      ),
    );
  }
}
