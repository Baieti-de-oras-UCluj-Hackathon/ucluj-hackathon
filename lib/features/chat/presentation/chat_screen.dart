import 'package:flutter/material.dart';

import '../../../core/primitives/app_button.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../match_intelligence/presentation/match_intelligence_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({
    required this.onTabSelected,
    this.onProfileTap,
    super.key,
  });

  final ValueChanged<AppTab> onTabSelected;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentTab: AppTab.chat,
      onTabSelected: onTabSelected,
      onProfileTap: onProfileTap,
      body: ListView(
        children: [
          Text(
            'DIRECT CHANNEL',
            style: TypographyTokens.sectionLabel.copyWith(
              color: ColorTokens.accent,
            ),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 3, height: 96, color: ColorTokens.accent),
              const SizedBox(width: SpacingTokens.md),
              Text(
                'MANAGER\nCHAT',
                style: TypographyTokens.displayHero.copyWith(fontSize: 58),
              ),
            ],
          ),
          const SizedBox(height: SpacingTokens.xl),
          Text(
            'MATCHDAY TACTICS - OCT 24',
            style: TypographyTokens.sectionLabel,
          ),
          const SizedBox(height: SpacingTokens.lg),
          _MessageBlock(
            author: 'A. KONTE',
            time: '09:10 AM',
            message:
                'Data indicates a drop in high-intensity sprints after minute 60. I propose a deeper mid-block for tomorrow. Thoughts?',
          ),
          const SizedBox(height: SpacingTokens.lg),
          _MessageBlock(
            author: 'YOU',
            time: '09:22 AM',
            message:
                'Agreed. Keep compact transition shape and protect wing channels in phase two. Send adjusted drill plan.',
            isUser: true,
          ),
          const SizedBox(height: SpacingTokens.lg),
          _MessageBlock(
            author: 'M. ROSSI',
            time: '10:05 AM',
            message:
                'Heatmaps updated. If we sit deeper, vertical release to striker must stay immediate. Direct vertical model fits.',
          ),
          const SizedBox(height: SpacingTokens.md),
          Container(
            padding: const EdgeInsets.all(SpacingTokens.md),
            color: ColorTokens.surfaceHigh,
            child: Text(
              'TACTICAL_REPORT_V2.PDF',
              style: TypographyTokens.sectionLabel.copyWith(
                color: ColorTokens.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: SpacingTokens.lg),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  padding:
                      const EdgeInsets.symmetric(horizontal: SpacingTokens.sm),
                  alignment: Alignment.centerLeft,
                  color: ColorTokens.surfaceLow,
                  child: Text(
                    'WRITE TACTICAL BRIEF',
                    style: TypographyTokens.sectionLabel,
                  ),
                ),
              ),
              const SizedBox(width: SpacingTokens.sm),
              SizedBox(
                width: 120,
                child: AppButton.primary(
                  label: 'Send',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => MatchIntelligenceScreen(
                          onTabSelected: onTabSelected,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageBlock extends StatelessWidget {
  const _MessageBlock({
    required this.author,
    required this.time,
    required this.message,
    this.isUser = false,
  });

  final String author;
  final String time;
  final String message;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          '$author   $time',
          style: TypographyTokens.sectionLabel.copyWith(
            color: isUser ? ColorTokens.textMuted : ColorTokens.accent,
          ),
        ),
        const SizedBox(height: SpacingTokens.xs),
        Text(
          message,
          textAlign: isUser ? TextAlign.right : TextAlign.left,
          style: TypographyTokens.body.copyWith(fontSize: 28 / 2),
        ),
      ],
    );
  }
}
