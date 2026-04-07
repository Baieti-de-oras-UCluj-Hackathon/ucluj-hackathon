import 'package:flutter/material.dart';

import '../../../core/primitives/app_card.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_scaffold.dart';

class StandingsScreen extends StatelessWidget {
  const StandingsScreen({
    required this.onTabSelected,
    super.key,
  });

  final ValueChanged<AppTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'League Standings',
      currentTab: AppTab.standings,
      onTabSelected: onTabSelected,
      body: ListView(
        children: [
          Text('COMPETITION / LIGA 1', style: TypographyTokens.sectionLabel),
          const SizedBox(height: SpacingTokens.sm),
          Text('LEAGUE',
              style: TypographyTokens.displayHero.copyWith(fontSize: 64)),
          Text(
            'STANDINGS',
            style: TypographyTokens.displayHero.copyWith(
              fontSize: 64,
              color: ColorTokens.surfaceHigh,
            ),
          ),
          const SizedBox(height: SpacingTokens.md),
          Container(
            color: ColorTokens.surfaceLow,
            padding: const EdgeInsets.all(SpacingTokens.sm),
            child: Text(
              'OVERALL   HOME   AWAY   FORM',
              style: TypographyTokens.sectionLabel
                  .copyWith(color: ColorTokens.accent),
            ),
          ),
          const SizedBox(height: SpacingTokens.md),
          const _TableRow(pos: '01', club: 'CFR CLUJ', points: '+22'),
          const _TableRow(pos: '02', club: 'FCSB', points: '+18'),
          Container(
            color: ColorTokens.surfaceHigh,
            padding: const EdgeInsets.all(SpacingTokens.md),
            child: const _TableRow(
                pos: '03', club: 'UMBRARO', points: '+28', highlighted: true),
          ),
          const _TableRow(pos: '04', club: 'U CRAIOVA', points: '+12'),
          const _TableRow(pos: '05', club: 'RAPID BUCURESTI', points: '+8'),
          const SizedBox(height: SpacingTokens.lg),
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WIN PROBABILITY', style: TypographyTokens.sectionLabel),
                SizedBox(height: SpacingTokens.xs),
                Text('88%', style: TypographyTokens.displayHero),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({
    required this.pos,
    required this.club,
    required this.points,
    this.highlighted = false,
  });

  final String pos;
  final String club;
  final String points;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final color = highlighted ? ColorTokens.accent : ColorTokens.textPrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: SpacingTokens.sm, horizontal: SpacingTokens.xs),
      child: Row(
        children: [
          SizedBox(
              width: 36,
              child: Text(pos,
                  style: TypographyTokens.body.copyWith(color: color))),
          Expanded(
              child: Text(club,
                  style: TypographyTokens.body
                      .copyWith(color: color, fontWeight: FontWeight.w700))),
          Text(points, style: TypographyTokens.body.copyWith(color: color)),
        ],
      ),
    );
  }
}
