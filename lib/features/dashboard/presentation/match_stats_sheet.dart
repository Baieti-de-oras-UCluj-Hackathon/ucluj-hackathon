import 'package:flutter/material.dart';

import '../../../core/constants/supported_formations.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../data/models/week_fixture.dart';
import '../../../data/models/match_preview.dart' show MatchPreviewResponse;
import '../../../data/repositories/xi_repository.dart';
import '../../team/presentation/recommended_xi_fifa_panel.dart';

// ── Prescription blueprint widget ──────────────────────────────────────────

class _PrescriptionBlueprint extends StatelessWidget {
  const _PrescriptionBlueprint({required this.prescription});
  final Prescription prescription;

  @override
  Widget build(BuildContext context) {
    final uplift = prescription.improvement;
    final bestPct = '${(prescription.bestProb * 100).round()}%';
    final upliftPct = '+${(uplift * 100).round()}%';
    final recs = prescription.recommendations;

    return Container(
      decoration: BoxDecoration(
        color: ColorTokens.surfaceLow,
        border: Border.all(color: ColorTokens.accent.withValues(alpha: 0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            color: ColorTokens.accent.withValues(alpha: 0.12),
            padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.md, vertical: SpacingTokens.sm),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome,
                    color: ColorTokens.accent, size: 14),
                const SizedBox(width: SpacingTokens.xs),
                Text('PLAN TACTIC OPTIM',
                    style: TypographyTokens.sectionLabel
                        .copyWith(color: ColorTokens.accent, fontSize: 11)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: ColorTokens.positive.withValues(alpha: 0.15),
                    border: Border.all(
                        color: ColorTokens.positive.withValues(alpha: 0.5)),
                  ),
                  child: Text(upliftPct,
                      style: TypographyTokens.sectionLabel
                          .copyWith(color: ColorTokens.positive, fontSize: 10)),
                ),
              ],
            ),
          ),

          // ── Projected probability ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                SpacingTokens.md, SpacingTokens.md, SpacingTokens.md, SpacingTokens.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(bestPct,
                    style: TypographyTokens.displayHero
                        .copyWith(color: ColorTokens.positive, fontSize: 40)),
                const SizedBox(width: SpacingTokens.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PROBABILITATE',
                        style: TypographyTokens.sectionLabel.copyWith(fontSize: 8)),
                    Text('PROIECTATĂ',
                        style: TypographyTokens.sectionLabel.copyWith(fontSize: 8)),
                  ],
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: SpacingTokens.md),
            child: Divider(height: 1, color: ColorTokens.divider),
          ),

          // ── Recommendation chips ─────────────────────────────────────────
          if (recs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(SpacingTokens.md),
              child: Wrap(
                spacing: SpacingTokens.sm,
                runSpacing: SpacingTokens.sm,
                children: recs.map(_buildRecChip).toList(),
              ),
            ),

          // ── Footer ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                SpacingTokens.md, 0, SpacingTokens.md, SpacingTokens.sm),
            child: Text(
              'CatBoost · 800 simulări · date Liga 1 2020–2025',
              style: TypographyTokens.sectionLabel
                  .copyWith(color: ColorTokens.textMuted, fontSize: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecChip(PrescriptionRec rec) {
    final isUp = rec.direction == 'up';
    final color = isUp ? ColorTokens.positive : ColorTokens.accent;
    final arrow = isUp ? '▲' : '▼';
    final unitStr = rec.unit;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.sm, vertical: SpacingTokens.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rec.label.toUpperCase(),
              style: TypographyTokens.sectionLabel
                  .copyWith(color: ColorTokens.textMuted, fontSize: 8)),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(arrow,
                  style: TypographyTokens.sectionLabel
                      .copyWith(color: color, fontSize: 10)),
              const SizedBox(width: 3),
              Text(
                '${rec.current}$unitStr → ${rec.target}$unitStr',
                style: TypographyTokens.body.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: ColorTokens.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MatchStatsSheet extends StatefulWidget {
  const MatchStatsSheet({
    required this.fixture,
    required this.myTeam,
    super.key,
  });

  final WeekFixture fixture;
  final String myTeam;

  @override
  State<MatchStatsSheet> createState() => _MatchStatsSheetState();
}

class _MatchStatsSheetState extends State<MatchStatsSheet> {
  final _xiRepo = XiRepository();
  bool _loadingXi = false;
  MatchPreviewResponse? _preview;
  String? _xiError;
  String _formation = '4-3-3';

  static const _formations = kSupportedFormations;

  @override
  void initState() {
    super.initState();
    _loadXi();
  }

  Future<void> _loadXi() async {
    setState(() { _loadingXi = true; _xiError = null; });
    try {
      final f = widget.fixture;
      final opponent = f.isUCLujHome ? f.awayTeam : f.homeTeam;
      final preview = await _xiRepo.fetchMatchPreview(
        opponentName: opponent,
        formation: _formation,
      );
      if (mounted) setState(() { _preview = preview; _loadingXi = false; });
    } catch (e) {
      if (mounted) setState(() { _xiError = e.toString(); _loadingXi = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.fixture;
    final screenH = MediaQuery.of(context).size.height;
    // Backend now returns U Cluj-centric win probability for this card.
    final uclProb = f.homeWinProbability;

    return Container(
      height: screenH * 0.92,
      decoration: const BoxDecoration(
        color: ColorTokens.surface,
        border: Border(top: BorderSide(color: ColorTokens.accent, width: 2)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: SpacingTokens.sm),
              width: 40,
              height: 3,
              color: ColorTokens.divider,
            ),
          ),
          // Header
          _buildHeader(f, uclProb),
          const Divider(height: 1, color: ColorTokens.divider),
          // Scrollable body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(SpacingTokens.md),
              children: [
                // Score or "upcoming" badge
                _buildMatchStatus(f),
                const SizedBox(height: SpacingTokens.xl),

                // ML prediction block — only for upcoming matches
                if (!f.isCompleted && uclProb != null) ...[
                  _buildMLBlock(f, uclProb),
                  const SizedBox(height: SpacingTokens.xl),
                ],

                // Key drivers — only for upcoming matches
                if (!f.isCompleted && f.keyDrivers.isNotEmpty) ...[
                  _sectionLabel('FACTORI CHEIE AI'),
                  const SizedBox(height: SpacingTokens.sm),
                  ...f.keyDrivers.map(_buildDriverRow),
                  const SizedBox(height: SpacingTokens.md),
                ],

                // Risks — only for upcoming matches
                if (!f.isCompleted && f.topRisks.isNotEmpty) ...[
                  _sectionLabel('RISCURI'),
                  const SizedBox(height: SpacingTokens.sm),
                  ...f.topRisks.map((r) => _buildDriverRow(r, isRisk: true)),
                  const SizedBox(height: SpacingTokens.md),
                ],

                // Prescription blueprint — only for upcoming matches
                if (!f.isCompleted && f.prescription != null) ...[
                  _sectionLabel('DIAGNOSTIC — PLAN TACTIC'),
                  const SizedBox(height: SpacingTokens.sm),
                  _PrescriptionBlueprint(prescription: f.prescription!),
                  const SizedBox(height: SpacingTokens.xl),
                ] else if (!f.isCompleted && f.narrative.isNotEmpty) ...[
                  _sectionLabel('DIAGNOSTIC'),
                  const SizedBox(height: SpacingTokens.sm),
                  Container(
                    color: ColorTokens.surfaceLow,
                    padding: const EdgeInsets.all(SpacingTokens.md),
                    child: Text(f.narrative,
                        style: TypographyTokens.body
                            .copyWith(color: ColorTokens.textMuted, fontSize: 13)),
                  ),
                  const SizedBox(height: SpacingTokens.xl),
                ],

                // XI section — only for U Cluj matches
                if (f.involvesUCluj) ...[
                  _buildXiSection(),
                ],

                const SizedBox(height: SpacingTokens.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(WeekFixture f, double? uclProb) {
    final homeDisplay = f.homeTeam.replaceAll('Universitatea Cluj', 'U CLUJ').toUpperCase();
    final awayDisplay = f.awayTeam.replaceAll('Universitatea Cluj', 'U CLUJ').toUpperCase();

    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.md),
      child: Row(
        children: [
          Expanded(
            child: Text(homeDisplay,
                style: TypographyTokens.body
                    .copyWith(fontWeight: FontWeight.w800, fontSize: 13),
                textAlign: TextAlign.center),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.sm, vertical: SpacingTokens.xs),
            color: ColorTokens.surfaceHigh,
            child: Text('VS',
                style: TypographyTokens.sectionLabel
                    .copyWith(color: ColorTokens.accent)),
          ),
          Expanded(
            child: Text(awayDisplay,
                style: TypographyTokens.body
                    .copyWith(fontWeight: FontWeight.w800, fontSize: 13),
                textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchStatus(WeekFixture f) {
    if (f.isCompleted) {
      final isHome = f.isUCLujHome;
      final myScore = isHome ? f.homeScore! : f.awayScore!;
      final theirScore = isHome ? f.awayScore! : f.homeScore!;
      String result;
      Color col;
      if (myScore > theirScore) { result = 'VICTORIE'; col = ColorTokens.positive; }
      else if (myScore < theirScore) { result = 'ÎNFRÂNGERE'; col = ColorTokens.negative; }
      else { result = 'EGAL'; col = ColorTokens.accent; }

      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${f.homeScore}',
                  style: TypographyTokens.displayHero.copyWith(fontSize: 64)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md),
                child: Text('—',
                    style: TypographyTokens.displayHero.copyWith(
                        fontSize: 32, color: ColorTokens.textMuted)),
              ),
              Text('${f.awayScore}',
                  style: TypographyTokens.displayHero.copyWith(fontSize: 64)),
            ],
          ),
          const SizedBox(height: SpacingTokens.xs),
          if (f.involvesUCluj)
            Container(
              color: col.withValues(alpha: 0.15),
              padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.md, vertical: SpacingTokens.xs),
              child: Text(result,
                  style: TypographyTokens.sectionLabel.copyWith(color: col)),
            ),
        ],
      );
    }

    // Upcoming
    return Container(
      color: ColorTokens.surfaceLow,
      padding: const EdgeInsets.all(SpacingTokens.md),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: ColorTokens.accent, size: 14),
          const SizedBox(width: SpacingTokens.xs),
          Text(f.displayDate,
              style: TypographyTokens.sectionLabel.copyWith(color: ColorTokens.accent)),
          if (f.venue != null) ...[
            Text('  ·  ${f.venue}',
                style: TypographyTokens.sectionLabel),
          ],
        ],
      ),
    );
  }

  Widget _buildMLBlock(WeekFixture f, double uclProb) {
    final winPct  = (uclProb * 100).round();
    final restPct = 100 - winPct;
    final col = uclProb >= 0.55
        ? ColorTokens.positive
        : uclProb >= 0.40
            ? ColorTokens.accent
            : ColorTokens.negative;

    return Container(
      color: ColorTokens.surfaceLow,
      padding: const EdgeInsets.all(SpacingTokens.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ȘANSĂ DE CÂȘTIG — U CLUJ',
                    style: TypographyTokens.sectionLabel),
                const SizedBox(height: SpacingTokens.xs),
                // Win probability large
                Text('$winPct%',
                    style: TypographyTokens.displayHero
                        .copyWith(color: col, fontSize: 44)),
                const SizedBox(height: SpacingTokens.xs),
                // Breakdown row
                Row(
                  children: [
                    _OutcomePill(label: 'CÂȘTIG', pct: winPct, color: col),
                    const SizedBox(width: SpacingTokens.xs),
                    _OutcomePill(
                        label: 'EGAL + ÎNFRÂNGERE',
                        pct: restPct,
                        color: ColorTokens.textMuted),
                  ],
                ),
                const SizedBox(height: SpacingTokens.xs),
                Text('CatBoost · model binar (câștig vs. rest)',
                    style: TypographyTokens.sectionLabel.copyWith(fontSize: 8)),
              ],
            ),
          ),
          const SizedBox(width: SpacingTokens.sm),
          _ProbBar(probability: uclProb, color: col),
        ],
      ),
    );
  }

  Widget _buildDriverRow(WeekFixtureDriver d, {bool isRisk = false}) {
    final col = isRisk ? ColorTokens.negative : ColorTokens.positive;
    final sign = isRisk ? '▼' : '▲';
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      color: ColorTokens.surfaceLow,
      padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.md, vertical: SpacingTokens.sm),
      child: Row(
        children: [
          Text(sign,
              style: TypographyTokens.sectionLabel
                  .copyWith(color: col, fontSize: 9)),
          const SizedBox(width: SpacingTokens.xs),
          Expanded(
              child: Text(d.label.toUpperCase(),
                  style: TypographyTokens.body.copyWith(fontSize: 12))),
          Text(
            '${(d.importance * 100).toStringAsFixed(0)}%',
            style: TypographyTokens.body
                .copyWith(color: col, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildXiSection() {
    if (_loadingXi) {
      return const Padding(
        padding: EdgeInsets.all(SpacingTokens.xl),
        child: Center(child: CircularProgressIndicator(color: ColorTokens.accent)),
      );
    }
    if (_xiError != null) {
      return Container(
        color: ColorTokens.surfaceLow,
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Text('XI indisponibil: $_xiError',
            style: TypographyTokens.body
                .copyWith(color: ColorTokens.textMuted, fontSize: 12)),
      );
    }
    if (_preview == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionLabel('XI RECOMANDAT'),
            const Spacer(),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _formation,
                dropdownColor: ColorTokens.surfaceLow,
                style: TypographyTokens.body
                    .copyWith(color: ColorTokens.textPrimary, fontSize: 12),
                icon: const Icon(Icons.keyboard_arrow_down,
                    color: ColorTokens.accent, size: 16),
                onChanged: (v) {
                  if (v != null && v != _formation) {
                    setState(() => _formation = v);
                    _loadXi();
                  }
                },
                items: _formations
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: SpacingTokens.sm),
        RecommendedXiFifaPanel(
          preview: _preview!,
          formation: _formation,
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Row(
        children: [
          Container(width: 2, height: 12, color: ColorTokens.accent),
          const SizedBox(width: SpacingTokens.xs),
          Text(text, style: TypographyTokens.sectionLabel),
        ],
      );

  String _sectionLabelStr(String s) => s;
}

class _OutcomePill extends StatelessWidget {
  const _OutcomePill({
    required this.label,
    required this.pct,
    required this.color,
  });
  final String label;
  final int pct;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$pct%',
              style: TypographyTokens.sectionLabel
                  .copyWith(color: color, fontSize: 10)),
          const SizedBox(width: 3),
          Text(label,
              style: TypographyTokens.sectionLabel
                  .copyWith(color: color.withValues(alpha: 0.7), fontSize: 8)),
        ],
      ),
    );
  }
}

class _ProbBar extends StatelessWidget {
  const _ProbBar({required this.probability, required this.color});
  final double probability;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 80,
          width: 20,
          child: RotatedBox(
            quarterTurns: 3,
            child: LinearProgressIndicator(
              value: probability,
              backgroundColor: ColorTokens.surfaceHigh,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 20,
            ),
          ),
        ),
      ],
    );
  }
}
