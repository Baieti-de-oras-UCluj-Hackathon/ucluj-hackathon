import 'package:flutter/material.dart';

import '../../../core/state/auth_state.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/typography_tokens.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({required this.authState, super.key});

  final AuthState authState;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _tabIndex = 0;
  static const _tabs = ['OVERVIEW', 'ACTIVITY', 'ACCOUNT'];

  AuthUser? get _user => widget.authState.user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const Divider(height: 1, color: ColorTokens.divider),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  SpacingTokens.xl,
                  SpacingTokens.xl,
                  SpacingTokens.xl,
                  SpacingTokens.xxl,
                ),
                children: [
                  _buildProfileHero(),
                  const SizedBox(height: SpacingTokens.xl),
                  _buildSegmentedControl(),
                  const SizedBox(height: SpacingTokens.xl),
                  if (_tabIndex == 0) _buildOverview(),
                  if (_tabIndex == 1) _buildActivity(),
                  if (_tabIndex == 2) _buildAccount(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SpacingTokens.md,
        SpacingTokens.md,
        SpacingTokens.md,
        SpacingTokens.sm,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(
              Icons.arrow_back,
              size: 20,
              color: ColorTokens.accent,
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          Text(
            'PROFILE',
            style: TypographyTokens.sectionLabel.copyWith(
              color: ColorTokens.textPrimary,
              letterSpacing: 2.4,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(
              Icons.close,
              size: 20,
              color: ColorTokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHero() {
    final name = _user?.email.split('@').first ?? 'Coach';
    final team = _user?.teamName ?? 'No Team';
    final role = _user?.role.toUpperCase() ?? 'COACH';

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: ColorTokens.surfaceHigh,
            border: Border.all(color: ColorTokens.accent, width: 2),
          ),
          child: const Icon(
            Icons.person,
            size: 40,
            color: ColorTokens.textMuted,
          ),
        ),
        const SizedBox(height: SpacingTokens.md),
        Text(
          name.toUpperCase(),
          style: TypographyTokens.headline.copyWith(fontSize: 22),
        ),
        const SizedBox(height: SpacingTokens.xxs),
        Text(role, style: TypographyTokens.sectionLabel),
        const SizedBox(height: SpacingTokens.xs),
        Text(
          team,
          style: TypographyTokens.body.copyWith(
            color: ColorTokens.accent,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: SpacingTokens.lg),
        const _MetaRow(
          leftLabel: 'MEMBER SINCE',
          leftValue: 'Apr 2026',
          rightLabel: 'PLATFORM',
          rightValue: 'Pro',
        ),
      ],
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: ColorTokens.surfaceLow,
        border: Border.all(color: ColorTokens.divider),
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final selected = _tabIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = i),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? ColorTokens.surfaceHigh : Colors.transparent,
                  border: selected
                      ? const Border(
                          bottom: BorderSide(color: ColorTokens.accent, width: 2),
                        )
                      : null,
                ),
                child: Text(
                  _tabs[i],
                  style: TypographyTokens.sectionLabel.copyWith(
                    color: selected ? ColorTokens.accent : ColorTokens.textMuted,
                    letterSpacing: 1.6,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // OVERVIEW TAB
  // ---------------------------------------------------------------------------

  Widget _buildOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PLATFORM USAGE', style: TypographyTokens.sectionLabel),
        const SizedBox(height: SpacingTokens.md),
        const Row(
          children: [
            Expanded(child: _StatCard(value: '18', label: 'BRIEFS\nGENERATED')),
            SizedBox(width: SpacingTokens.sm),
            Expanded(child: _StatCard(value: '42', label: 'SIMULATIONS\nRUN')),
          ],
        ),
        const SizedBox(height: SpacingTokens.sm),
        const Row(
          children: [
            Expanded(child: _StatCard(value: '7', label: 'SAVED\nBLUEPRINTS')),
            SizedBox(width: SpacingTokens.sm),
            Expanded(child: _StatCard(value: '5', label: 'REPORTS\nEXPORTED')),
          ],
        ),
        const SizedBox(height: SpacingTokens.xl),
        const Divider(height: 1, color: ColorTokens.divider),
        const SizedBox(height: SpacingTokens.xl),
        Text('CLUB CONTEXT', style: TypographyTokens.sectionLabel),
        const SizedBox(height: SpacingTokens.md),
        _InfoRow(
          label: 'PREFERRED TEAM',
          value: _user?.teamName ?? '—',
        ),
        const _InfoRow(label: 'LAST ANALYZED', value: 'vs CFR Cluj'),
        const _InfoRow(label: 'LEAGUE', value: 'Romanian Superliga'),
        const _InfoRow(label: 'SEASON', value: '2024–2025'),
        const SizedBox(height: SpacingTokens.xl),
        const Divider(height: 1, color: ColorTokens.divider),
        const SizedBox(height: SpacingTokens.xl),
        Text('COACHING PROFILE', style: TypographyTokens.sectionLabel),
        const SizedBox(height: SpacingTokens.md),
        const _InfoRow(label: 'TACTICAL STYLE', value: 'Structured Pressure'),
        const _InfoRow(label: 'FORMATION PREF', value: '4-2-3-1'),
        const _InfoRow(label: 'FOCUS AREA', value: 'Set-Piece Optimization'),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ACTIVITY TAB
  // ---------------------------------------------------------------------------

  Widget _buildActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RECENT ACTIVITY', style: TypographyTokens.sectionLabel),
        const SizedBox(height: SpacingTokens.md),
        const _ActivityItem(
          action: 'Generated tactical brief',
          detail: 'FCSB vs CFR Cluj',
          time: '2h ago',
        ),
        const _ActivityItem(
          action: 'Ran Monte Carlo simulation',
          detail: 'FCSB vs Rapid București',
          time: '1d ago',
        ),
        const _ActivityItem(
          action: 'Exported match report',
          detail: 'FCSB vs Universitatea Craiova',
          time: '3d ago',
        ),
        const _ActivityItem(
          action: 'Saved tactical blueprint',
          detail: 'High-possession overload plan',
          time: '5d ago',
        ),
        const _ActivityItem(
          action: 'Analyzed fixture probabilities',
          detail: 'Round 28 — full batch',
          time: '1w ago',
        ),
        const SizedBox(height: SpacingTokens.xl),
        const Divider(height: 1, color: ColorTokens.divider),
        const SizedBox(height: SpacingTokens.xl),
        Text('SAVED BRIEFS', style: TypographyTokens.sectionLabel),
        const SizedBox(height: SpacingTokens.md),
        const _SavedItem(title: 'vs CFR Cluj — Match Brief', date: 'Mar 28, 2026'),
        const _SavedItem(title: 'vs Rapid — Tactical Blueprint', date: 'Mar 21, 2026'),
        const _SavedItem(title: 'vs U Craiova — Key Drivers Report', date: 'Mar 14, 2026'),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ACCOUNT TAB
  // ---------------------------------------------------------------------------

  Widget _buildAccount(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PLAN & ACCESS', style: TypographyTokens.sectionLabel),
        const SizedBox(height: SpacingTokens.md),
        const _InfoRow(label: 'PLAN', value: 'Pro — Thesis Build'),
        _InfoRow(label: 'EMAIL', value: _user?.email ?? '—'),
        _InfoRow(
          label: 'ROLE',
          value: _user?.role.toUpperCase() ?? '—',
        ),
        const _InfoRow(label: 'STATUS', value: 'ACTIVE'),
        const SizedBox(height: SpacingTokens.xl),
        const Divider(height: 1, color: ColorTokens.divider),
        const SizedBox(height: SpacingTokens.xl),
        Text('PREFERENCES', style: TypographyTokens.sectionLabel),
        const SizedBox(height: SpacingTokens.md),
        const _InfoRow(label: 'LANGUAGE', value: 'English'),
        const _InfoRow(label: 'NOTIFICATIONS', value: 'Enabled'),
        const _InfoRow(label: 'EXPORT FORMAT', value: 'PDF'),
        const _InfoRow(label: 'DEFAULT VIEW', value: 'Dashboard'),
        const SizedBox(height: SpacingTokens.xl),
        const Divider(height: 1, color: ColorTokens.divider),
        const SizedBox(height: SpacingTokens.xl),
        Text('SECURITY', style: TypographyTokens.sectionLabel),
        const SizedBox(height: SpacingTokens.md),
        const _InfoRow(label: 'PASSWORD', value: '••••••••'),
        const _InfoRow(label: 'TWO-FACTOR', value: 'Not enabled'),
        const _InfoRow(label: 'LAST LOGIN', value: 'Today'),
        const SizedBox(height: SpacingTokens.xxl),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.transparent,
              shape: const RoundedRectangleBorder(),
              side: const BorderSide(color: ColorTokens.negative),
            ),
            onPressed: () async {
              await widget.authState.logout();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: Text(
              'LOGOUT',
              style: TypographyTokens.sectionLabel.copyWith(
                color: ColorTokens.negative,
                letterSpacing: 2.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: SpacingTokens.md),
        Center(
          child: Text(
            'UmbraRo v0.1.0 — Thesis Build',
            style: TypographyTokens.sectionLabel.copyWith(
              color: ColorTokens.textMuted.withValues(alpha: 0.5),
              fontSize: 9,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// REUSABLE WIDGETS
// =============================================================================

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
  });

  final String leftLabel, leftValue, rightLabel, rightValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.sm,
      ),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: ColorTokens.divider),
          bottom: BorderSide(color: ColorTokens.divider),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(leftLabel, style: TypographyTokens.sectionLabel),
                const SizedBox(height: SpacingTokens.xxs),
                Text(leftValue, style: TypographyTokens.body),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rightLabel, style: TypographyTokens.sectionLabel),
                const SizedBox(height: SpacingTokens.xxs),
                Text(rightValue, style: TypographyTokens.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.md),
      color: ColorTokens.surfaceLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TypographyTokens.headline.copyWith(
              fontSize: 32,
              color: ColorTokens.accent,
            ),
          ),
          const SizedBox(height: SpacingTokens.xs),
          Text(label, style: TypographyTokens.sectionLabel),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TypographyTokens.sectionLabel),
          Flexible(
            child: Text(
              value,
              style: TypographyTokens.body.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({
    required this.action,
    required this.detail,
    required this.time,
  });

  final String action;
  final String detail;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
      padding: const EdgeInsets.all(SpacingTokens.md),
      color: ColorTokens.surfaceLow,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 40,
            color: ColorTokens.accent,
          ),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.toUpperCase(),
                  style: TypographyTokens.sectionLabel.copyWith(
                    color: ColorTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: SpacingTokens.xxs),
                Text(detail, style: TypographyTokens.body),
              ],
            ),
          ),
          Text(
            time,
            style: TypographyTokens.sectionLabel.copyWith(fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _SavedItem extends StatelessWidget {
  const _SavedItem({required this.title, required this.date});

  final String title;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpacingTokens.sm),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, size: 16, color: ColorTokens.accent),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(
            child: Text(
              title,
              style: TypographyTokens.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Text(date, style: TypographyTokens.sectionLabel),
        ],
      ),
    );
  }
}
