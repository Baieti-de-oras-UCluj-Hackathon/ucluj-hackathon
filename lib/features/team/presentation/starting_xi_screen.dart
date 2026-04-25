import 'package:flutter/material.dart';

import '../../../core/primitives/app_button.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../data/models/xi_prediction.dart';
import '../../../data/repositories/xi_repository.dart';

class StartingXiScreen extends StatefulWidget {
  const StartingXiScreen({
    required this.onTabSelected,
    this.onProfileTap,
    super.key,
  });

  final ValueChanged<AppTab> onTabSelected;
  final VoidCallback? onProfileTap;

  @override
  State<StartingXiScreen> createState() => _StartingXiScreenState();
}

class _StartingXiScreenState extends State<StartingXiScreen> {
  final _xiRepository = XiRepository();
  bool _isLoading = false;
  bool _isLoadingOpponents = true;
  XiPredictionResponse? _prediction;
  String _selectedFormation = '4-3-3';
  String? _errorMessage;
  String? _opponentsError;

  int? _selectedOpponentId;
  final Map<int, String> _opponents = {};

  final List<String> _formations = [
    '4-3-3',
    '4-4-2',
    '4-2-3-1',
    '3-5-2',
    '3-4-3',
    '5-3-2',
    '5-4-1',
  ];

  @override
  void initState() {
    super.initState();
    _loadOpponentOptions();
  }

  Future<void> _loadOpponentOptions() async {
    try {
      final opponents = await _xiRepository.fetchOpponentOptions();
      if (!mounted) return;

      setState(() {
        _opponents
          ..clear()
          ..addEntries(opponents.map((o) => MapEntry(o.id, o.name)));
        _selectedOpponentId =
            opponents.isNotEmpty ? opponents.first.id : null;
        _isLoadingOpponents = false;
        _opponentsError = opponents.isEmpty
            ? 'No opponent options available.'
            : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingOpponents = false;
        _opponentsError = 'Could not load opponent teams: $e';
      });
    }
  }

  Future<void> _generateXi() async {
    if (_selectedOpponentId == null) {
      setState(() {
        _errorMessage = 'Please select an opponent team first.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _xiRepository.predictXi(
        formation: _selectedFormation,
        opponentTeamId: _selectedOpponentId,
      );
      setState(() {
        _prediction = response;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentTab: AppTab.team,
      onTabSelected: widget.onTabSelected,
      onProfileTap: widget.onProfileTap,
      body: ListView(
        children: [
          Text('TACTICAL BLUEPRINT',
              style: TypographyTokens.sectionLabel
                  .copyWith(color: ColorTokens.accent)),
          const SizedBox(height: SpacingTokens.xs),
          Text('STARTING XI',
              style: TypographyTokens.displayHero.copyWith(fontSize: 48)),
          const SizedBox(height: SpacingTokens.xl),
          
          // Form
          _buildDropdowns(),
          const SizedBox(height: SpacingTokens.md),
          
          AppButton.primary(
            label: _isLoading ? 'GENERATING...' : 'GENERATE XI',
            onPressed: _isLoading ? null : () => _generateXi(),
          ),
          
          if (_errorMessage != null) ...[
            const SizedBox(height: SpacingTokens.md),
            Text('Error: $_errorMessage', style: TypographyTokens.body.copyWith(color: ColorTokens.negative)),
          ],

          const SizedBox(height: SpacingTokens.xl),
          
          if (_prediction != null && !_isLoading) _buildResults(),
        ],
      ),
    );
  }

  Widget _buildDropdowns() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FORMATION', style: TypographyTokens.sectionLabel),
        const SizedBox(height: SpacingTokens.xs),
        Container(
          color: ColorTokens.surface,
          padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.md),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              dropdownColor: ColorTokens.surface,
              value: _selectedFormation,
              style: TypographyTokens.body.copyWith(color: ColorTokens.textPrimary),
              onChanged: (v) {
                if (v != null) setState(() => _selectedFormation = v);
              },
              items: _formations.map((f) => DropdownMenuItem(
                value: f,
                child: Text(f),
              )).toList(),
            ),
          ),
        ),
        const SizedBox(height: SpacingTokens.md),
        Text('OPPONENT', style: TypographyTokens.sectionLabel),
        const SizedBox(height: SpacingTokens.xs),
        if (_isLoadingOpponents)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: SpacingTokens.sm),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ColorTokens.accent,
              ),
            ),
          )
        else if (_opponentsError != null)
          Text(
            _opponentsError!,
            style: TypographyTokens.body.copyWith(color: ColorTokens.negative),
          )
        else
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: ColorTokens.surface,
              border: Border.all(color: ColorTokens.surfaceLow, width: 1),
            ),
            child: ListView.builder(
              itemCount: _opponents.length,
              itemBuilder: (context, index) {
                final entry = _opponents.entries.elementAt(index);
                final isSelected = _selectedOpponentId == entry.key;
                return InkWell(
                  onTap: () => setState(() => _selectedOpponentId = entry.key),
                  child: Container(
                    padding: const EdgeInsets.all(SpacingTokens.sm),
                    color: isSelected ? ColorTokens.accent.withOpacity(0.2) : null,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.value,
                            style: TypographyTokens.body.copyWith(
                              color: isSelected ? ColorTokens.accent : ColorTokens.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check, color: ColorTokens.accent, size: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SELECTED XI', style: TypographyTokens.sectionLabel.copyWith(color: ColorTokens.accent)),
        const SizedBox(height: SpacingTokens.sm),
        _buildPlayerList(_prediction!.startingXI),
        
        const SizedBox(height: SpacingTokens.xl),
        Text('BENCH', style: TypographyTokens.sectionLabel),
        const SizedBox(height: SpacingTokens.sm),
        _buildPlayerList(_prediction!.bench),
        const SizedBox(height: SpacingTokens.xl),
      ],
    );
  }

  Widget _buildPlayerList(List<XiPlayer> players) {
    if (players.isEmpty) return Text('No players available.', style: TypographyTokens.body);
    
    // Group by roleGroup (GK, DEF, MID, FWD)
    final order = ['GK', 'DEF', 'MID', 'FWD'];
    List<Widget> sections = [];
    
    for (var group in order) {
      final groupPlayers = players.where((p) => p.roleGroup == group).toList();
      if (groupPlayers.isEmpty) continue;
      
      sections.add(
        Padding(
          padding: const EdgeInsets.only(top: SpacingTokens.md, bottom: SpacingTokens.xs),
          child: Text(group, style: TypographyTokens.sectionLabel),
        )
      );
      
      for (var p in groupPlayers) {
        sections.add(
          Container(
            margin: const EdgeInsets.only(bottom: 2),
            color: ColorTokens.surfaceLow,
            padding: const EdgeInsets.all(SpacingTokens.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.shortName, style: TypographyTokens.headline.copyWith(fontSize: 16)),
                      Text(p.role, style: TypographyTokens.body.copyWith(color: ColorTokens.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(p.predictedScore.toStringAsFixed(2), style: TypographyTokens.headline.copyWith(color: ColorTokens.accent, fontSize: 16)),
                    Text('SCORE', style: TypographyTokens.body.copyWith(color: ColorTokens.textMuted, fontSize: 10)),
                  ],
                ),
              ],
            ),
          )
        );
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections,
    );
  }
}
