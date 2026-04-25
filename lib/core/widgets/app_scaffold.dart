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
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/teams/universitatea_cluj.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.xs),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'U CLUJ',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          height: 1.0,
                          letterSpacing: 1.5,
                          color: ColorTokens.accent,
                        ),
                      ),
                      Text(
                        'TACTICAL INTELLIGENCE',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 8,
                          height: 1.2,
                          letterSpacing: 2.0,
                          color: ColorTokens.textMuted,
                        ),
                      ),
                    ],
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
                            borderRadius: BorderRadius.circular(4),
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
            Container(
              height: 2,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorTokens.accent,
                    ColorTokens.accentStrong,
                    Color(0x00000000),
                  ],
                ),
              ),
            ),
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
