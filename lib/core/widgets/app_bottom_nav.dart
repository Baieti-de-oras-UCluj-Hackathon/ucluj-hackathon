import 'package:flutter/material.dart';

import '../theme/color_tokens.dart';
import '../theme/typography_tokens.dart';

enum AppTab { dashboard, standings, chat, analytics, team }

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.current,
    required this.onSelected,
    super.key,
  });

  final AppTab current;
  final ValueChanged<AppTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: current.index,
      onTap: (index) => onSelected(AppTab.values[index]),
      elevation: 0,
      backgroundColor: ColorTokens.surface,
      selectedItemColor: ColorTokens.accent,
      unselectedItemColor: ColorTokens.textMuted,
      selectedLabelStyle: TypographyTokens.navLabel,
      unselectedLabelStyle: TypographyTokens.navLabel,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'DASHBOARD',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.leaderboard_outlined),
          activeIcon: Icon(Icons.leaderboard),
          label: 'STANDINGS',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          activeIcon: Icon(Icons.chat_bubble),
          label: 'CHAT',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics_outlined),
          activeIcon: Icon(Icons.analytics),
          label: 'ANALYTICS',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.groups_outlined),
          activeIcon: Icon(Icons.groups),
          label: 'TEAM',
        ),
      ],
    );
  }
}
