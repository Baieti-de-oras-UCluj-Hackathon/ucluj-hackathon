import 'package:flutter/material.dart';

import '../../../core/primitives/app_card.dart';
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
      title: 'Team',
      currentTab: AppTab.team,
      onTabSelected: onTabSelected,
      body: const AppCard(
        child: Text(
          'TEAM PLACEHOLDER',
          style: TypographyTokens.headline,
        ),
      ),
    );
  }
}
