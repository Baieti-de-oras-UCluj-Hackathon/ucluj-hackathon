import 'package:flutter/material.dart';

import '../../../core/primitives/app_button.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../data/models/dashboard_data.dart';
import '../../../data/repositories/dashboard_repository.dart';
import '../../match_intelligence/presentation/match_intelligence_screen.dart';
import '../../team/presentation/match_preview_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    required this.onTabSelected,
    this.onProfileTap,
    super.key,
  });

  final ValueChanged<AppTab> onTabSelected;
  final VoidCallback? onProfileTap;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repo = DashboardRepository();

  bool _loading = true;
  String? _error;
  DashboardData? _data;

  static const String _myTeam = 'U Cluj';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repo.fetchDashboard();
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _openMatchPreview(DashboardFixture fixture) {
    final opponent = fixture.opponentOf(_myTeam);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MatchPreviewScreen(
          opponentName: opponent,
          myTeam: _myTeam,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentTab: AppTab.dashboard,
      onTabSelected: widget.onTabSelected,
      onProfileTap: widget.onProfileTap,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: ColorTokens.accent))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(SpacingTokens.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Could not load dashboard',
                            style: TypographyTokens.headline
                                .copyWith(color: ColorTokens.negative)),
                        const SizedBox(height: SpacingTokens.sm),
                        Text(_error!,
                            style: TypographyTokens.body
                                .copyWith(color: ColorTokens.textMuted),
                            textAlign: TextAlign.center),
                        const SizedBox(height: SpacingTokens.lg),
                        TextButton(
                          onPressed: _load,
                          child: Text('RETRY',
                              style: TypographyTokens.sectionLabel
                                  .copyWith(color: ColorTokens.accent)),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
              children: [
                _buildHero(),
                const SizedBox(height: SpacingTokens.xl),
                if (_data?.keyDrivers.isNotEmpty == true) ...[
                  Text('KEY DRIVERS', style: TypographyTokens.sectionLabel),
                  const SizedBox(height: SpacingTokens.sm),
                  const Divider(height: 1, color: ColorTokens.divider),
                  const SizedBox(height: SpacingTokens.md),
                  ..._data!.keyDrivers.map((d) => Padding(
                        padding: const EdgeInsets.only(bottom: SpacingTokens.md),
                        child: _DriverRow(
                          label: d.label.toUpperCase(),
                          delta: d.direction == 'positive' ? '+' : '-',
                          importance: d.importance,
                        ),
                      )),
                ],
                if (_data?.recentFixtures.isNotEmpty == true) ...[
                  const SizedBox(height: SpacingTokens.md),
                  Text('RECENT RESULTS', style: TypographyTokens.sectionLabel),
                  const SizedBox(height: SpacingTokens.sm),
                  ..._data!.recentFixtures.map(_buildRecentCard),
                ],
                const SizedBox(height: SpacingTokens.lg),
                Text('UPCOMING MATCHES', style: TypographyTokens.sectionLabel),
                const SizedBox(height: SpacingTokens.sm),
                if (_data?.upcomingFixtures.isEmpty != false)
                  Text('No upcoming matches found.',
                      style: TypographyTokens.body
                          .copyWith(color: ColorTokens.textMuted))
                else
                  ..._data!.upcomingFixtures.map(_buildUpcomingCard),
                const SizedBox(height: SpacingTokens.xl),
                AppButton.secondary(
                  label: 'Full AI Simulation',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => MatchIntelligenceScreen(
                          onTabSelected: widget.onTabSelected,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: SpacingTokens.xl),
              ],
            ),
    );
  }

  Widget _buildHero() {
    final prob = _data?.winProbability;
    final next = _data?.nextFixture;
    final pct = prob != null ? (prob * 100).round().toString() : '--';
    final opponent = next != null ? next.opponentOf(_myTeam).toUpperCase() : 'NEXT MATCH';

    return GestureDetector(
      onTap: next != null ? () => _openMatchPreview(next) : null,
      child: Column(
        children: [
          Center(
            child: Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ColorTokens.accent, width: 4),
              ),
              child: Center(
                child: Text(pct,
                    style: TypographyTokens.displayHero.copyWith(fontSize: 52)),
              ),
            ),
          ),
          const SizedBox(height: SpacingTokens.lg),
          Center(
            child: Text('VS $opponent',
                style: TypographyTokens.displayHero.copyWith(fontSize: 46)),
          ),
          const SizedBox(height: SpacingTokens.sm),
          Center(
            child: Text(
              next?.venue != null ? 'LIGA 1 · ${next!.venue!.toUpperCase()}' : 'LIGA 1 ROMANIA',
              style: TypographyTokens.sectionLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCard(DashboardFixture f) {
    final isHome = f.homeTeam == _myTeam;
    final myScore = isHome ? f.homeScore : f.awayScore;
    final theirScore = isHome ? f.awayScore : f.homeScore;
    final opponent = f.opponentOf(_myTeam);

    String result = '';
    if (myScore != null && theirScore != null) {
      if (myScore > theirScore) {
        result = 'W';
      } else if (myScore < theirScore) {
        result = 'L';
      } else {
        result = 'D';
      }
    }

    final resultColor = result == 'W'
        ? ColorTokens.positive
        : result == 'L'
            ? ColorTokens.negative
            : ColorTokens.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      color: ColorTokens.surfaceLow,
      padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.md, vertical: SpacingTokens.sm),
      child: Row(
        children: [
          Text(result,
              style: TypographyTokens.headline
                  .copyWith(color: resultColor, fontSize: 14)),
          const SizedBox(width: SpacingTokens.md),
          Expanded(
              child: Text(opponent.toUpperCase(), style: TypographyTokens.body)),
          Text(
            myScore != null ? '$myScore - $theirScore' : '',
            style: TypographyTokens.headline.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingCard(DashboardFixture fixture) {
    final opponent = fixture.opponentOf(_myTeam).toUpperCase();
    final date = fixture.matchDate.length >= 10
        ? fixture.matchDate.substring(0, 10)
        : fixture.matchDate;

    return GestureDetector(
      onTap: () => _openMatchPreview(fixture),
      child: Container(
        margin: const EdgeInsets.only(bottom: SpacingTokens.sm),
        color: ColorTokens.surfaceLow,
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('U CLUJ vs $opponent',
                      style: TypographyTokens.body
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(date,
                      style: TypographyTokens.body
                          .copyWith(color: ColorTokens.textMuted, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: ColorTokens.accent, size: 20),
          ],
        ),
      ),
    );
  }
}

class _DriverRow extends StatelessWidget {
  const _DriverRow({
    required this.label,
    required this.delta,
    required this.importance,
  });

  final String label;
  final String delta;
  final double importance;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: TypographyTokens.body)),
        Text(
          '$delta${(importance * 100).toStringAsFixed(0)}%',
          style: TypographyTokens.body.copyWith(
            color: ColorTokens.accent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
