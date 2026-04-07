import 'package:flutter/material.dart';

import '../../../core/primitives/app_card.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_scaffold.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({
    required this.onTabSelected,
    super.key,
  });

  final ValueChanged<AppTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Manager Chat',
      currentTab: AppTab.chat,
      onTabSelected: onTabSelected,
      body: const AppCard(
        child: Text(
          'CHAT PLACEHOLDER',
          style: TypographyTokens.headline,
        ),
      ),
    );
  }
}
