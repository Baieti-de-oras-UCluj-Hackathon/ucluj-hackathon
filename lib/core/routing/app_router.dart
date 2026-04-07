import 'package:flutter/material.dart';

import '../../features/analytics/presentation/analytics_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/standings/presentation/standings_screen.dart';
import '../../features/team/presentation/team_screen.dart';
import '../widgets/app_bottom_nav.dart';

class AppRoutes {
  const AppRoutes._();

  static const String root = '/';
}

class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppTab _currentTab = AppTab.dashboard;

  void _onTabSelected(AppTab tab) {
    if (_currentTab == tab) return;
    setState(() => _currentTab = tab);
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentTab) {
      case AppTab.dashboard:
        return DashboardScreen(onTabSelected: _onTabSelected);
      case AppTab.standings:
        return StandingsScreen(onTabSelected: _onTabSelected);
      case AppTab.chat:
        return ChatScreen(onTabSelected: _onTabSelected);
      case AppTab.analytics:
        return AnalyticsScreen(onTabSelected: _onTabSelected);
      case AppTab.team:
        return TeamScreen(onTabSelected: _onTabSelected);
    }
  }
}
