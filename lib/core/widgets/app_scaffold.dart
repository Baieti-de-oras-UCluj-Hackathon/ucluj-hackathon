import 'package:flutter/material.dart';

import '../theme/color_tokens.dart';
import '../theme/spacing_tokens.dart';
import '../theme/typography_tokens.dart';
import 'app_bottom_nav.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.title,
    required this.currentTab,
    required this.body,
    required this.onTabSelected,
    super.key,
  });

  final String title;
  final AppTab currentTab;
  final Widget body;
  final ValueChanged<AppTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title.toUpperCase(),
          style: TypographyTokens.sectionLabel.copyWith(
            color: ColorTokens.accent,
            letterSpacing: 1.8,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(SpacingTokens.md),
          child: body,
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        current: currentTab,
        onSelected: onTabSelected,
      ),
    );
  }
}
