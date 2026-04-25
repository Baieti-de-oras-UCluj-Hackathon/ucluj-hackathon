import 'package:flutter/material.dart';

import '../../../core/state/auth_state.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_scaffold.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class _Msg {
  _Msg({required this.text, required this.sender})
      : time = _now();

  final String text;
  final String sender;
  final String time;

  static String _now() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    required this.onTabSelected,
    this.authState,
    this.onProfileTap,
    super.key,
  });

  final ValueChanged<AppTab> onTabSelected;
  final AuthState? authState;
  final VoidCallback? onProfileTap;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _msgs = <_Msg>[];
  bool _typing = false;

  String get _senderName {
    final user = widget.authState?.user;
    final team = user?.teamName ?? '';
    if (team.isNotEmpty) return team.toUpperCase();
    final email = user?.email ?? '';
    return email.split('@').first.toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onTextChange);
  }

  void _onTextChange() {
    final t = _ctrl.text.isNotEmpty;
    if (t != _typing) setState(() => _typing = t);
  }

  @override
  void dispose() {
    _ctrl
      ..removeListener(_onTextChange)
      ..dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _msgs.add(_Msg(text: text, sender: _senderName));
      _ctrl.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentTab: AppTab.chat,
      onTabSelected: widget.onTabSelected,
      onProfileTap: widget.onProfileTap,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(teamName: widget.authState?.user?.teamName),
          Expanded(child: _buildList()),
          if (_typing) _buildTypingHint(),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_msgs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.forum_outlined,
                size: 40, color: ColorTokens.textMuted),
            const SizedBox(height: SpacingTokens.sm),
            Text(
              'NO MESSAGES YET',
              style: TypographyTokens.sectionLabel
                  .copyWith(color: ColorTokens.textMuted),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.md),
      itemCount: _msgs.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: SpacingTokens.md),
      itemBuilder: (_, i) => _Bubble(msg: _msgs[i]),
    );
  }

  Widget _buildTypingHint() {
    return Padding(
      padding: const EdgeInsets.only(
          bottom: SpacingTokens.xs, left: SpacingTokens.xxs),
      child: Row(
        children: [
          Container(width: 2, height: 14, color: ColorTokens.accent),
          const SizedBox(width: SpacingTokens.xs),
          Text(
            '$_senderName IS TYPING...',
            style: TypographyTokens.sectionLabel
                .copyWith(color: ColorTokens.accent),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      margin: const EdgeInsets.only(top: SpacingTokens.sm),
      decoration: const BoxDecoration(
        border: Border(
            top: BorderSide(color: ColorTokens.divider, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              style: TypographyTokens.body.copyWith(
                  color: ColorTokens.textPrimary, fontSize: 14),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Write a message...',
                hintStyle: TypographyTokens.body.copyWith(
                    color: ColorTokens.textMuted, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: SpacingTokens.sm, vertical: 14),
              ),
            ),
          ),
          _SendButton(onTap: _send),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({this.teamName});
  final String? teamName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SpacingTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TEAM CHANNEL',
            style: TypographyTokens.sectionLabel
                .copyWith(color: ColorTokens.accent),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 3, height: 72, color: ColorTokens.accent),
              const SizedBox(width: SpacingTokens.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TEAM CHAT',
                      style: TypographyTokens.displayHero
                          .copyWith(fontSize: 40)),
                  if (teamName != null && teamName!.isNotEmpty)
                    Text(
                      teamName!.toUpperCase(),
                      style: TypographyTokens.sectionLabel
                          .copyWith(color: ColorTokens.textMuted),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Message bubble ───────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg});
  final _Msg msg;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: SpacingTokens.xxs),
          child: Text(
            '${msg.sender}  ·  ${msg.time}',
            style: TypographyTokens.sectionLabel
                .copyWith(color: ColorTokens.textMuted),
          ),
        ),
        const SizedBox(height: SpacingTokens.xxs),
        Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.md,
                vertical: SpacingTokens.sm,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF0D2340),
                border: Border(
                  right: BorderSide(color: ColorTokens.accent, width: 2),
                ),
              ),
              child: Text(
                msg.text,
                style: TypographyTokens.body.copyWith(
                    color: ColorTokens.textPrimary, fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Send button ──────────────────────────────────────────────────────────────

class _SendButton extends StatelessWidget {
  const _SendButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 48,
        color: ColorTokens.accent,
        alignment: Alignment.center,
        child: const Icon(Icons.send_rounded,
            color: ColorTokens.onAccent, size: 20),
      ),
    );
  }
}
