import 'package:flutter/material.dart';

import '../../../core/primitives/app_card.dart';
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
      title: 'Analytics',
      currentTab: AppTab.analytics,
      onTabSelected: onTabSelected,
      body: const AppCard(
        child: Text(
          'ANALYTICS PLACEHOLDER',
          style: TypographyTokens.headline,
        ),
      ),
    );
  }
}
