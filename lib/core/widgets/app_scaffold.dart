import 'package:flutter/material.dart';

import '../theme/color_tokens.dart';
import '../theme/spacing_tokens.dart';
import 'app_bottom_nav.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.currentTab,
    required this.body,
    required this.onTabSelected,
    this.onProfileTap,
    this.trailing,
    super.key,
  });

  final AppTab currentTab;
  final Widget body;
  final ValueChanged<AppTab> onTabSelected;
  final VoidCallback? onProfileTap;
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
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: Image.asset(
                      'assets/branding/logo_icon.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.xs),
                  const Text(
                    'umbraro',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                      height: 1.0,
                      letterSpacing: -1.2,
                      color: ColorTokens.accent,
                    ),
                  ),
                  const Spacer(),
                  trailing ??
                      GestureDetector(
                        onTap: onProfileTap,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: ColorTokens.surfaceHigh,
                            border: Border.all(color: ColorTokens.divider),
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            size: 16,
                            color: ColorTokens.textPrimary,
                          ),
                        ),
                      ),
                ],
              ),
            ),
            const Divider(height: 1, color: ColorTokens.divider),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  SpacingTokens.xl,
                  SpacingTokens.xl,
                  SpacingTokens.xl,
                  SpacingTokens.md,
                ),
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
