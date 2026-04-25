import 'package:flutter/material.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../data/models/match_preview.dart';
import '../../../data/repositories/xi_repository.dart';

class MatchPreviewScreen extends StatefulWidget {
  const MatchPreviewScreen({
    required this.opponentName,
    required this.myTeam,
    super.key,
  });

  final String opponentName;
  final String myTeam;

  @override
  State<MatchPreviewScreen> createState() => _MatchPreviewScreenState();
}

class _MatchPreviewScreenState extends State<MatchPreviewScreen> {
  final _repo = XiRepository();

  bool _loading = true;
  String? _error;
  MatchPreviewResponse? _preview;

  String _formation = '4-3-3';

  static const _formations = [
    '4-3-3', '4-4-2', '4-2-3-1', '3-5-2', '3-4-3', '5-3-2', '5-4-1',
  ];

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
      final preview = await _repo.fetchMatchPreview(
        opponentName: widget.opponentName,
        formation: _formation,
      );
      if (mounted) {
        setState(() {
          _preview = preview;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorTokens.surface,
      appBar: AppBar(
        backgroundColor: ColorTokens.surface,
        foregroundColor: ColorTokens.textPrimary,
        elevation: 0,
        title: Text(
          '${widget.myTeam.toUpperCase()} VS ${widget.opponentName.toUpperCase()}',
          style: TypographyTokens.sectionLabel,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: SpacingTokens.md),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _formation,
                dropdownColor: ColorTokens.surfaceLow,
                style: TypographyTokens.body
                    .copyWith(color: ColorTokens.textPrimary),
                icon: const Icon(Icons.arrow_drop_down,
                    color: ColorTokens.accent),
                onChanged: (v) {
                  if (v != null && v != _formation) {
                    setState(() => _formation = v);
                    _load();
                  }
                },
                items: _formations
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: ColorTokens.accent))
          : _error != null
              ? _buildError()
              : _buildBody(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Failed to load preview',
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
    );
  }

  Widget _buildBody() {
    final p = _preview!;
    return ListView(
      padding: const EdgeInsets.all(SpacingTokens.md),
      children: [
        _buildStatsRow(p),
        const SizedBox(height: SpacingTokens.xl),
        if (p.headToHead.total > 0) ...[
          _buildH2H(p.headToHead),
          const SizedBox(height: SpacingTokens.xl),
        ],
        _buildXI(p),
        const SizedBox(height: SpacingTokens.xl),
        _buildBench(p.bench),
        const SizedBox(height: SpacingTokens.xl),
      ],
    );
  }

  Widget _buildStatsRow(MatchPreviewResponse p) {
    final s = p.teamStats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SQUAD ANALYTICS', style: TypographyTokens.sectionLabel),
        const SizedBox(height: SpacingTokens.sm),
        const Divider(color: ColorTokens.divider, height: 1),
        const SizedBox(height: SpacingTokens.md),
        Row(
          children: [
            _StatCell(
                label: 'AVG FORM',
                value: s.avgRecentForm.toStringAsFixed(1)),
            _StatCell(
                label: 'AVG PERF',
                value: s.avgPerformanceScore.toStringAsFixed(1)),
            _StatCell(
                label: 'PASS %',
                value: '${s.avgPassAccuracy.toStringAsFixed(0)}%'),
            _StatCell(
                label: 'DUEL %',
                value: '${s.avgDuelWinRate.toStringAsFixed(0)}%'),
          ],
        ),
        if (s.topScorer.isNotEmpty) ...[
          const SizedBox(height: SpacingTokens.md),
          Row(
            children: [
              Expanded(
                child: _NameStatCell(
                  label: 'TOP SCORER',
                  name: s.topScorer,
                  value: '${s.topScorerStat.toStringAsFixed(2)} G/90',
                ),
              ),
              const SizedBox(width: SpacingTokens.sm),
              if (s.topCreator.isNotEmpty)
                Expanded(
                  child: _NameStatCell(
                    label: 'TOP CREATOR',
                    name: s.topCreator,
                    value: '${s.topCreatorStat.toStringAsFixed(2)} KP/90',
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildH2H(H2HStats h) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('HEAD TO HEAD (LAST ${h.total})',
            style: TypographyTokens.sectionLabel),
        const SizedBox(height: SpacingTokens.sm),
        const Divider(color: ColorTokens.divider, height: 1),
        const SizedBox(height: SpacingTokens.md),
        Row(
          children: [
            _StatCell(label: 'WINS', value: '${h.ourWins}'),
            _StatCell(label: 'DRAWS', value: '${h.draws}'),
            _StatCell(label: 'LOSSES', value: '${h.theirWins}'),
            _StatCell(
                label: 'AVG SCORE',
                value:
                    '${h.ourAvgGoals.toStringAsFixed(1)}-${h.theirAvgGoals.toStringAsFixed(1)}'),
          ],
        ),
      ],
    );
  }

  Widget _buildXI(MatchPreviewResponse p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('STARTING XI', style: TypographyTokens.sectionLabel
                .copyWith(color: ColorTokens.accent)),
            Text(p.formation,
                style: TypographyTokens.sectionLabel),
          ],
        ),
        const SizedBox(height: SpacingTokens.sm),
        const Divider(color: ColorTokens.divider, height: 1),
        const SizedBox(height: SpacingTokens.sm),
        for (final group in ['GK', 'DEF', 'MID', 'FWD']) ...[
          ..._playersForGroup(p.startingXi, group).map(_buildPlayerRow),
        ],
      ],
    );
  }

  Widget _buildBench(List<MatchPreviewPlayer> bench) {
    if (bench.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('BENCH', style: TypographyTokens.sectionLabel),
        const SizedBox(height: SpacingTokens.sm),
        const Divider(color: ColorTokens.divider, height: 1),
        const SizedBox(height: SpacingTokens.sm),
        ...bench.map(_buildPlayerRow),
      ],
    );
  }

  List<MatchPreviewPlayer> _playersForGroup(
      List<MatchPreviewPlayer> players, String group) {
    return players.where((p) => p.roleGroup == group).toList();
  }

  Widget _buildPlayerRow(MatchPreviewPlayer p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      color: ColorTokens.surfaceLow,
      padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.md, vertical: SpacingTokens.sm),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              p.roleGroup,
              style: TypographyTokens.body.copyWith(
                  color: ColorTokens.textMuted, fontSize: 11),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.shortName,
                    style: TypographyTokens.body
                        .copyWith(fontWeight: FontWeight.w700)),
                Text(p.role,
                    style: TypographyTokens.body
                        .copyWith(color: ColorTokens.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                p.predictedScore.toStringAsFixed(2),
                style: TypographyTokens.headline
                    .copyWith(color: ColorTokens.accent, fontSize: 14),
              ),
              Text(
                '${p.keyStatLabel} ${p.keyStatValue.toStringAsFixed(2)}',
                style: TypographyTokens.body
                    .copyWith(color: ColorTokens.textMuted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color: ColorTokens.surfaceLow,
        margin: const EdgeInsets.only(right: 2),
        padding: const EdgeInsets.symmetric(
            vertical: SpacingTokens.sm, horizontal: SpacingTokens.xs),
        child: Column(
          children: [
            Text(value,
                style: TypographyTokens.headline.copyWith(fontSize: 16)),
            const SizedBox(height: 2),
            Text(label,
                style: TypographyTokens.body
                    .copyWith(color: ColorTokens.textMuted, fontSize: 9),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _NameStatCell extends StatelessWidget {
  const _NameStatCell(
      {required this.label, required this.name, required this.value});
  final String label;
  final String name;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorTokens.surfaceLow,
      padding: const EdgeInsets.all(SpacingTokens.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TypographyTokens.body
                  .copyWith(color: ColorTokens.textMuted, fontSize: 10)),
          const SizedBox(height: 2),
          Text(name,
              style: TypographyTokens.body
                  .copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
          Text(value,
              style: TypographyTokens.body
                  .copyWith(color: ColorTokens.accent, fontSize: 11)),
        ],
      ),
    );
  }
}
