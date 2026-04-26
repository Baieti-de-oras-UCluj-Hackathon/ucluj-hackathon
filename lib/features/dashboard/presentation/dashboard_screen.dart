import 'package:flutter/material.dart';

import '../../../core/state/auth_state.dart';
import '../../../core/services/api_client.dart' show ApiException;
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../data/models/week_fixture.dart';
import '../../../data/repositories/week_repository.dart';
import 'match_stats_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    required this.authState,
    required this.onTabSelected,
    this.onProfileTap,
    super.key,
  });

  final AuthState authState;
  final ValueChanged<AppTab> onTabSelected;
  final VoidCallback? onProfileTap;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final WeekRepository _repo;
  bool _loading = true;
  String? _error;
  List<WeekFixture> _fixtures = [];

  static const String _myTeam = 'Universitatea Cluj';

  @override
  void initState() {
    super.initState();
    _repo = WeekRepository(apiClient: widget.authState.api);
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _repo.fetchWeekFixtures();
      if (mounted) setState(() { _fixtures = data; _loading = false; });
    } catch (e) {
      if (mounted) {
        if (e is ApiException && e.statusCode == 401) {
          // Auto logout on 401
          widget.authState.logout();
          return;
        }
        setState(() { _error = e.toString(); _loading = false; });
      }
    }
  }

  void _openStats(WeekFixture f) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MatchStatsSheet(fixture: f, myTeam: _myTeam),
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
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Eroare la încărcare', style: TypographyTokens.headline.copyWith(color: ColorTokens.negative)),
          const SizedBox(height: SpacingTokens.sm),
          Text(_error!, style: TypographyTokens.body.copyWith(color: ColorTokens.textMuted), textAlign: TextAlign.center),
          const SizedBox(height: SpacingTokens.lg),
          TextButton(onPressed: _load, child: Text('RETRY', style: TypographyTokens.sectionLabel.copyWith(color: ColorTokens.accent))),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Sort: UCL fixtures first, then others
    final uclFixtures = _fixtures.where((f) => f.involvesUCluj).toList();
    final otherFixtures = _fixtures.where((f) => !f.involvesUCluj).toList();

    return RefreshIndicator(
      color: ColorTokens.accent,
      backgroundColor: ColorTokens.surfaceHigh,
      onRefresh: _load,
      child: ListView(
        children: [
          // Week header
          _buildWeekHeader(),
          const SizedBox(height: SpacingTokens.xl),

          // U Cluj section
          if (uclFixtures.isNotEmpty) ...[
            _buildSectionLabel('U CLUJ — ACEASTĂ SĂPTĂMÂNĂ', ColorTokens.accent),
            const SizedBox(height: SpacingTokens.sm),
            ...uclFixtures.map((f) => _buildMatchCard(f, highlight: true)),
            const SizedBox(height: SpacingTokens.xl),
          ],

          // Other Liga 1 matches
          if (otherFixtures.isNotEmpty) ...[
            _buildSectionLabel('LIGA 1 — ALTE MECIURI', ColorTokens.textMuted),
            const SizedBox(height: SpacingTokens.sm),
            ...otherFixtures.map((f) => _buildMatchCard(f, highlight: false)),
          ],

          if (_fixtures.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(SpacingTokens.xxl),
                child: Text('Nu există meciuri această săptămână.',
                    style: TypographyTokens.body.copyWith(color: ColorTokens.textMuted),
                    textAlign: TextAlign.center),
              ),
            ),

          const SizedBox(height: SpacingTokens.xxl),
        ],
      ),
    );
  }

  Widget _buildWeekHeader() {
    final label = _visibleRangeLabel();

    return Container(
      color: ColorTokens.surfaceLow,
      padding: const EdgeInsets.all(SpacingTokens.md),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: ColorTokens.accent, size: 16),
          const SizedBox(width: SpacingTokens.sm),
          Text('INTERVAL AFIȘAT', style: TypographyTokens.sectionLabel),
          const Spacer(),
          Text(label, style: TypographyTokens.sectionLabel.copyWith(color: ColorTokens.accent)),
        ],
      ),
    );
  }

  String _visibleRangeLabel() {
    final parsed = _fixtures
        .map((f) => DateTime.tryParse(f.matchDate))
        .whereType<DateTime>()
        .toList()
      ..sort();

    if (parsed.isNotEmpty) {
      final start = parsed.first;
      final end = parsed.last;
      return '${_fmtDate(start, withYear: start.year != end.year)} — ${_fmtDate(end, withYear: true)}';
    }

    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    return '${_fmtDate(monday)} — ${_fmtDate(sunday, withYear: true)}';
  }

  String _fmtDate(DateTime d, {bool withYear = false}) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    if (withYear) return '$dd.$mm.${d.year}';
    return '$dd.$mm';
  }

  Widget _buildSectionLabel(String text, Color color) {
    return Row(
      children: [
        Container(width: 3, height: 14, color: color),
        const SizedBox(width: SpacingTokens.xs),
        Text(text, style: TypographyTokens.sectionLabel.copyWith(color: color)),
      ],
    );
  }

  Widget _buildMatchCard(WeekFixture f, {required bool highlight}) {
    final isHome = f.isUCLujHome;
    // Backend returns P(U Cluj Win) already — use directly, no flip needed.
    final prob = f.homeWinProbability;
    final uclProb = highlight ? prob : prob;

    final probPct = uclProb != null ? '${(uclProb * 100).round()}%' : '--';
    final probColor = uclProb == null
        ? ColorTokens.textMuted
        : uclProb >= 0.55
            ? ColorTokens.positive
            : uclProb >= 0.40
                ? ColorTokens.accent
                : ColorTokens.negative;

    String result = '';
    Color resultColor = ColorTokens.textMuted;
    if (f.isCompleted && highlight) {
      final myScore = isHome ? f.homeScore! : f.awayScore!;
      final theirScore = isHome ? f.awayScore! : f.homeScore!;
      if (myScore > theirScore) { result = 'V'; resultColor = ColorTokens.positive; }
      else if (myScore < theirScore) { result = 'Î'; resultColor = ColorTokens.negative; }
      else { result = 'E'; resultColor = ColorTokens.accent; }
    }

    return GestureDetector(
      onTap: () => _openStats(f),
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: highlight ? ColorTokens.surfaceLow : ColorTokens.surfaceLow,
          border: highlight
              ? const Border(left: BorderSide(color: ColorTokens.accent, width: 3))
              : null,
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.md, vertical: SpacingTokens.md),
        child: Column(
          children: [
            Row(
              children: [
                // Result badge (if completed)
                if (result.isNotEmpty) ...[
                  Container(
                    width: 24,
                    height: 24,
                    color: resultColor.withValues(alpha: 0.15),
                    child: Center(
                      child: Text(result,
                          style: TypographyTokens.sectionLabel
                              .copyWith(color: resultColor, fontSize: 10)),
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.sm),
                ],

                // Teams
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _teamRow(f.homeTeam, highlight && isHome),
                      const SizedBox(height: 4),
                      _teamRow(f.awayTeam, highlight && !isHome),
                    ],
                  ),
                ),

                // Score or probability
                f.isCompleted
                    ? _scoreBlock(f)
                    : _probabilityBlock(probPct, probColor, highlight),
              ],
            ),

            // Date + venue
            const SizedBox(height: SpacingTokens.xs),
            Row(
              children: [
                Text(f.displayDate,
                    style: TypographyTokens.body
                        .copyWith(color: ColorTokens.textMuted, fontSize: 10)),
                if (f.venue != null) ...[
                  Text('  ·  ${f.venue}',
                      style: TypographyTokens.body
                          .copyWith(color: ColorTokens.textMuted, fontSize: 10)),
                ],
                const Spacer(),
                Text('ANALIZĂ  ›',
                    style: TypographyTokens.sectionLabel
                        .copyWith(color: ColorTokens.accent, fontSize: 9)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _teamRow(String name, bool isMine) {
    // Normalize display name
    final display = name.replaceAll('Universitatea Cluj', 'U CLUJ');
    return Text(
      display.toUpperCase(),
      style: TypographyTokens.body.copyWith(
        fontWeight: isMine ? FontWeight.w800 : FontWeight.w400,
        color: isMine ? ColorTokens.textPrimary : ColorTokens.textMuted,
        fontSize: 13,
      ),
    );
  }

  Widget _scoreBlock(WeekFixture f) {
    return Container(
      color: ColorTokens.surfaceHigh,
      padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.sm, vertical: SpacingTokens.xs),
      child: Text(
        '${f.homeScore} — ${f.awayScore}',
        style: TypographyTokens.headline.copyWith(fontSize: 18, letterSpacing: 2),
      ),
    );
  }

  Widget _probabilityBlock(String pct, Color color, bool highlight) {
    if (!highlight) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(pct,
            style: TypographyTokens.headline.copyWith(
                color: color, fontSize: 22, letterSpacing: 0)),
        Text('WIN PROB',
            style: TypographyTokens.sectionLabel.copyWith(fontSize: 8)),
      ],
    );
  }
}
