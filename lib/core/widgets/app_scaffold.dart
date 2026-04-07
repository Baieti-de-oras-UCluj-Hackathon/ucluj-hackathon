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
    this.trailing,
    super.key,
  });

  final String title;
  final AppTab currentTab;
  final Widget body;
  final ValueChanged<AppTab> onTabSelected;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SpacingTokens.md,
                SpacingTokens.md,
                SpacingTokens.md,
                SpacingTokens.sm,
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu, size: 20, color: ColorTokens.accent),
                  const SizedBox(width: SpacingTokens.sm),
                  Text(
                    title.toLowerCase(),
                    style: TypographyTokens.headline.copyWith(
                      fontSize: 30,
                      color: ColorTokens.accent,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const Spacer(),
                  trailing ??
                      Container(
                        width: 32,
                        height: 32,
                        color: ColorTokens.surfaceHigh,
                      ),
                ],
              ),
            ),
            const Divider(height: 1, color: ColorTokens.divider),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(SpacingTokens.md),
                child: body,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        current: currentTab,
        onSelected: onTabSelected,
      ),
    );
  }
}
