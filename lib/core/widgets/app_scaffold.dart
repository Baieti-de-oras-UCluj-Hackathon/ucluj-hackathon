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
                  const SizedBox(
                    width: 115,
                    height: 32,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'umbraro',
                        style: TextStyle(
                          fontStyle: FontStyle.normal,
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                          height: 1 / 24,
                          letterSpacing: -1.2,
                          color: ColorTokens.accent,
                        ),
                      ),
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
