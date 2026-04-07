import 'package:flutter/material.dart';

import '../theme/color_tokens.dart';
import '../theme/spacing_tokens.dart';
import 'app_bottom_nav.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.currentTab,
    required this.body,
    required this.onTabSelected,
    this.trailing,
    super.key,
  });

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
                  SizedBox(
                    width: 140,
                    height: 32,
                    child: Image.asset(
                      'assets/branding/umbraro_wordmark.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
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
