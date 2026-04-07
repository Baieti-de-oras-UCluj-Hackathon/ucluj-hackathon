import 'package:flutter/material.dart';

import '../../../core/primitives/app_card.dart';
import '../../../core/primitives/app_button.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_scaffold.dart';

class TeamScreen extends StatelessWidget {
  const TeamScreen({
    required this.onTabSelected,
    super.key,
  });

  final ValueChanged<AppTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentTab: AppTab.team,
      onTabSelected: onTabSelected,
      body: ListView(
        children: [
          Text('SEASON STATUS', style: TypographyTokens.sectionLabel),
          const SizedBox(height: SpacingTokens.sm),
          Text('RANK #3',
              style: TypographyTokens.displayHero.copyWith(fontSize: 76)),
          const SizedBox(height: SpacingTokens.sm),
          Text('46 PTS', style: TypographyTokens.headline),
          const SizedBox(height: SpacingTokens.lg),
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PERFORMANCE SUMMARY',
                    style: TypographyTokens.sectionLabel),
                SizedBox(height: SpacingTokens.sm),
                Text('WIN RATE 68%   GOALS/MATCH 2.41',
                    style: TypographyTokens.body),
                SizedBox(height: SpacingTokens.xs),
                Text('CLEAN SHEETS 12   TOP-4 RATE 54%',
                    style: TypographyTokens.body),
              ],
            ),
          ),
          const SizedBox(height: SpacingTokens.md),
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SQUAD LOAD MONITORING',
                    style: TypographyTokens.sectionLabel),
                SizedBox(height: SpacingTokens.sm),
                Text('HENDERSON   OPTIMAL', style: TypographyTokens.body),
                SizedBox(height: SpacingTokens.xs),
                Text('RASHFORD   ROTATION', style: TypographyTokens.body),
                SizedBox(height: SpacingTokens.xs),
                Text('FERNANDES   CAUTION', style: TypographyTokens.body),
              ],
            ),
          ),
          const SizedBox(height: SpacingTokens.md),
          Container(
            color: ColorTokens.accent,
            padding: const EdgeInsets.all(SpacingTokens.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TACTICAL ALERT: MATCH PLAN DEVIATION',
                  style: TypographyTokens.sectionLabel.copyWith(
                    color: ColorTokens.onAccent,
                  ),
                ),
                const SizedBox(height: SpacingTokens.sm),
                Text(
                  'Midfield defensive transition lags 1.4s behind opposition average.',
                  style: TypographyTokens.body
                      .copyWith(color: ColorTokens.onAccent),
                ),
                const SizedBox(height: SpacingTokens.sm),
                AppButton.secondary(label: 'Open Match Plan', onPressed: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
