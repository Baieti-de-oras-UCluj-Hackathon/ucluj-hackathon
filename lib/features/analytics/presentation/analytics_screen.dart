import 'package:flutter/material.dart';

import '../../../core/primitives/app_card.dart';
import '../../../core/primitives/app_button.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_scaffold.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({
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
          Text('WIN PROBABILITY SCORE', style: TypographyTokens.sectionLabel),
          const SizedBox(height: SpacingTokens.xs),
          Text('78.4%',
              style: TypographyTokens.displayHero.copyWith(fontSize: 82)),
          const SizedBox(height: SpacingTokens.lg),
          const Divider(height: 1, color: ColorTokens.divider),
          const SizedBox(height: SpacingTokens.lg),
          Text('TACTICAL FORM',
              style: TypographyTokens.headline.copyWith(fontSize: 42)),
          const SizedBox(height: SpacingTokens.sm),
          const _MetricLine(label: 'SHOTS', value: '18.4'),
          const _MetricLine(label: 'ON TARGET', value: '6.2'),
          const _MetricLine(label: 'POSSESSION', value: '58%'),
          const SizedBox(height: SpacingTokens.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ACTIVE RECOMMENDATION',
                    style: TypographyTokens.sectionLabel),
                const SizedBox(height: SpacingTokens.sm),
                Text('HIGH-BLOCK TRANSITION',
                    style: TypographyTokens.body
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: SpacingTokens.sm),
                Text(
                  'Shift to 4-3-3 pressing structure at 60. Recovery times are lagging behind baseline.',
                  style: TypographyTokens.body,
                ),
                const SizedBox(height: SpacingTokens.md),
                AppButton.secondary(
                    label: 'Execute Simulation', onPressed: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TypographyTokens.sectionLabel),
          Text(
            value,
            style: TypographyTokens.body.copyWith(
              color: ColorTokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
