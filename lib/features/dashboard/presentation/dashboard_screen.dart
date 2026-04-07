import 'package:flutter/material.dart';

import '../../../core/primitives/app_card.dart';
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
      title: 'UmbraRo',
      currentTab: AppTab.dashboard,
      onTabSelected: onTabSelected,
      body: const AppCard(
        child: Text(
          'DASHBOARD PLACEHOLDER',
          style: TypographyTokens.headline,
        ),
      ),
    );
  }
}
