import 'package:flutter/material.dart';

import '../../../core/primitives/app_button.dart';
import '../../../core/primitives/app_card.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../match_intelligence/presentation/match_intelligence_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.onTabSelected,
    this.onProfileTap,
    super.key,
  });

  final ValueChanged<AppTab> onTabSelected;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentTab: AppTab.dashboard,
      onTabSelected: onTabSelected,
      onProfileTap: onProfileTap,
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Image.asset('assets/teams/universitatea_cluj.png', fit: BoxFit.contain),
                ),
                const SizedBox(width: SpacingTokens.sm),
                Text(
                  'VS FCSB',
                  style: TypographyTokens.displayHero.copyWith(fontSize: 46),
                ),
                const SizedBox(width: SpacingTokens.sm),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Image.asset('assets/teams/fcsb.png', fit: BoxFit.contain),
                ),
              ],
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Center(
            child: Text('LIGA 1 ROMANIA - CLUJ ARENA',
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
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('COMPLETED', style: TypographyTokens.sectionLabel),
                SizedBox(height: SpacingTokens.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('FARUL CONSTANȚA', style: TypographyTokens.body),
                    Text('1', style: TypographyTokens.headline),
                  ],
                ),
                SizedBox(height: SpacingTokens.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('U CLUJ', style: TypographyTokens.body.copyWith(color: ColorTokens.accent, fontWeight: FontWeight.w700)),
                    Text('2', style: TypographyTokens.headline.copyWith(color: ColorTokens.accent)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: SpacingTokens.md),
          Container(
            color: ColorTokens.surfaceLow,
            padding: const EdgeInsets.all(SpacingTokens.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NEXT UP', style: TypographyTokens.sectionLabel),
                const SizedBox(height: SpacingTokens.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('U CLUJ',
                        style: TypographyTokens.body
                            .copyWith(fontWeight: FontWeight.w700, color: ColorTokens.accent)),
                    Text('VS', style: TypographyTokens.headline),
                  ],
                ),
                const SizedBox(height: SpacingTokens.xs),
                Text('FCSB', style: TypographyTokens.body),
              ],
            ),
          ),
          const SizedBox(height: SpacingTokens.md),
          AppCard(
            backgroundColor: ColorTokens.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('UPCOMING', style: TypographyTokens.sectionLabel),
                SizedBox(height: SpacingTokens.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('RAPID BUCUREȘTI', style: TypographyTokens.body),
                    Text('VS', style: TypographyTokens.headline),
                  ],
                ),
                SizedBox(height: SpacingTokens.xs),
                Text('U CLUJ', style: TypographyTokens.body.copyWith(color: ColorTokens.accent, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: SpacingTokens.lg),
          Container(
            color: ColorTokens.surfaceLow,
            padding: const EdgeInsets.all(SpacingTokens.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SQUAD LOAD', style: TypographyTokens.sectionLabel),
                      const SizedBox(height: SpacingTokens.xs),
                      Text('OPTIMAL', style: TypographyTokens.headline),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('EFFICIENCY', style: TypographyTokens.sectionLabel),
                      const SizedBox(height: SpacingTokens.xs),
                      Text('8.4', style: TypographyTokens.headline),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: SpacingTokens.md),
          const Row(
            children: [
              Expanded(
                child: _DriverRow(label: '', value: '2ND', delta: 'THIS WEEK'),
              ),
              SizedBox(width: SpacingTokens.sm),
              Expanded(
                child:
                    _DriverRow(label: '', value: '+22', delta: 'STABLE TREND'),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.md),
          AppButton.primary(
            label: 'Generate Detailed Brief',
            onPressed: () {},
          ),
          const SizedBox(height: SpacingTokens.sm),
          AppButton.secondary(
            label: 'Full AI Simulation',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MatchIntelligenceScreen(
                    onTabSelected: onTabSelected,
                  ),
                ),
              );
            },
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
