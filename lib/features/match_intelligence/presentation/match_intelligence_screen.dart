import 'package:flutter/material.dart';

import '../../../core/primitives/app_button.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_scaffold.dart';

class MatchIntelligenceScreen extends StatelessWidget {
  const MatchIntelligenceScreen({
    required this.onTabSelected,
    super.key,
  });

  final ValueChanged<AppTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentTab: AppTab.analytics,
      onTabSelected: onTabSelected,
      body: ListView(
        children: [
          Text('MATCH INTELLIGENCE',
              style: TypographyTokens.sectionLabel
                  .copyWith(color: ColorTokens.accent)),
          const SizedBox(height: SpacingTokens.xs),
          Text('VS. FCSB',
              style: TypographyTokens.displayHero.copyWith(fontSize: 58)),
          const SizedBox(height: SpacingTokens.xs),
          Text('OCT 24 • ARENA NATIONALA',
              style: TypographyTokens.sectionLabel),
          const SizedBox(height: SpacingTokens.xl),
          Text('WIN PROBABILITY OPTIMIZATION',
              style: TypographyTokens.sectionLabel),
          const SizedBox(height: SpacingTokens.md),
          Row(
            children: [
              Expanded(
                child: _Box(label: 'BASELINE', value: '65%'),
              ),
              const SizedBox(width: 1),
              Expanded(
                child: _Box(
                  label: 'AI-OPTIMIZED',
                  value: '74%',
                  valueColor: ColorTokens.accent,
                  footer: '+9.0% UPLIFT',
                ),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('VICTORY CHANCE',
                  style: TypographyTokens.sectionLabel
                      .copyWith(color: ColorTokens.accent)),
              Text('74%',
                  style: TypographyTokens.headline
                      .copyWith(color: ColorTokens.accent)),
            ],
          ),
          const SizedBox(height: SpacingTokens.xs),
          Container(
            height: 6,
            color: ColorTokens.surfaceLow,
            child: FractionallySizedBox(
              widthFactor: 0.74,
              alignment: Alignment.centerLeft,
              child: Container(color: ColorTokens.accent),
            ),
          ),
          const SizedBox(height: SpacingTokens.xl),
          Text('TACTICAL BLUEPRINT', style: TypographyTokens.sectionLabel),
          const SizedBox(height: SpacingTokens.sm),
          const _MetricGrid(),
          const SizedBox(height: SpacingTokens.lg),
          Container(
            color: ColorTokens.surfaceLow,
            padding: const EdgeInsets.all(SpacingTokens.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TACTICAL DIAGNOSIS',
                    style: TypographyTokens.sectionLabel
                        .copyWith(color: ColorTokens.accent)),
                const SizedBox(height: SpacingTokens.sm),
                Text(
                  'The uplift is achieved by transitioning to a high-press 4-3-3 variant. Prioritize wide-area pressure to trigger wing-back fatigue.',
                  style: TypographyTokens.body,
                ),
              ],
            ),
          ),
          const SizedBox(height: SpacingTokens.lg),
          AppButton.primary(label: 'Generate Detailed Brief', onPressed: () {}),
          const SizedBox(height: SpacingTokens.sm),
          AppButton.secondary(label: 'Full AI Simulation', onPressed: () {}),
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({
    required this.label,
    required this.value,
    this.valueColor = ColorTokens.textPrimary,
    this.footer,
  });

  final String label;
  final String value;
  final Color valueColor;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorTokens.surface,
      padding: const EdgeInsets.all(SpacingTokens.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TypographyTokens.sectionLabel),
          const SizedBox(height: SpacingTokens.xs),
          Text(value,
              style: TypographyTokens.displayHero
                  .copyWith(fontSize: 58, color: valueColor)),
          if (footer != null) ...[
            const SizedBox(height: SpacingTokens.xs),
            Text(footer!,
                style: TypographyTokens.sectionLabel
                    .copyWith(color: ColorTokens.accent)),
          ],
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid();

  @override
  Widget build(BuildContext context) {
    Widget cell(String label, String value,
        {Color color = ColorTokens.textPrimary}) {
      return Container(
        color: ColorTokens.surface,
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TypographyTokens.sectionLabel),
            const SizedBox(height: SpacingTokens.xs),
            Text(value,
                style: TypographyTokens.headline.copyWith(color: color)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(children: [
          Expanded(child: cell('POSSESSION', '58%')),
          const SizedBox(width: 1),
          Expanded(child: cell('SHOTS', '14'))
        ]),
        const SizedBox(height: 1),
        Row(children: [
          Expanded(child: cell('S.O.T.', '6')),
          const SizedBox(width: 1),
          Expanded(child: cell('CORNERS', '8'))
        ]),
        const SizedBox(height: 1),
        Row(
          children: [
            Expanded(child: cell('XG TARGET', '2.1')),
            const SizedBox(width: 1),
            Expanded(
                child: cell('XGA LIMIT', '0.4', color: ColorTokens.negative)),
          ],
        ),
      ],
    );
  }
}
