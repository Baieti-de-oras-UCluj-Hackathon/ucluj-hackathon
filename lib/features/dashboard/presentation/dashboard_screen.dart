import 'package:flutter/material.dart';

import '../../../core/primitives/app_card.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_scaffold.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.onTabSelected,
    super.key,
  });

  final ValueChanged<AppTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentTab: AppTab.dashboard,
      onTabSelected: onTabSelected,
      body: ListView(
        children: [
          Center(
            child: Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ColorTokens.accent, width: 4),
              ),
              child: Center(
                child: Text(
                  '74',
                  style: TypographyTokens.displayHero.copyWith(fontSize: 56),
                ),
              ),
            ),
          ),
          const SizedBox(height: SpacingTokens.lg),
          Center(
            child: Text(
              'VS FCSB',
              style: TypographyTokens.displayHero.copyWith(fontSize: 58),
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Center(
            child: Text('LIGA 1 ROMANIA - ARENA NATIONALA',
                style: TypographyTokens.sectionLabel),
          ),
          const SizedBox(height: SpacingTokens.xl),
          Text('KEY DRIVERS', style: TypographyTokens.sectionLabel),
          const SizedBox(height: SpacingTokens.sm),
          const Divider(height: 1, color: ColorTokens.divider),
          const SizedBox(height: SpacingTokens.md),
          const _DriverRow(
            label: 'POSSESSION',
            value: '62% Zone Entry Efficiency',
            delta: '+4%',
          ),
          const SizedBox(height: SpacingTokens.md),
          const _DriverRow(
            label: 'OPPONENT WEAKNESS',
            value: 'Flank Structural Collapse',
            delta: '18%',
          ),
          const SizedBox(height: SpacingTokens.md),
          const _DriverRow(
            label: 'SET PIECE XG',
            value: 'Near-post Zonal Targeting',
            delta: '0.42',
          ),
          const SizedBox(height: SpacingTokens.xl),
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('COMPLETED', style: TypographyTokens.sectionLabel),
                SizedBox(height: SpacingTokens.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('FARUL', style: TypographyTokens.body),
                    Text('3', style: TypographyTokens.headline),
                  ],
                ),
                SizedBox(height: SpacingTokens.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('UMBRARO', style: TypographyTokens.body),
                    Text('4', style: TypographyTokens.headline),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverRow extends StatelessWidget {
  const _DriverRow({
    required this.label,
    required this.value,
    required this.delta,
  });

  final String label;
  final String value;
  final String delta;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TypographyTokens.sectionLabel),
        const SizedBox(height: SpacingTokens.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(value, style: TypographyTokens.body)),
            Text(
              delta,
              style: TypographyTokens.body.copyWith(
                color: ColorTokens.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
