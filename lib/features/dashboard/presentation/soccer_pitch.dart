import 'package:flutter/material.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/typography_tokens.dart';
import '../../../data/models/match_preview.dart';

class SoccerPitch extends StatelessWidget {
  const SoccerPitch({
    required this.players,
    required this.formation,
    super.key,
  });

  final List<MatchPreviewPlayer> players;
  final String formation;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.1,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1B5E20), // Deep grass green
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            _buildPitchLines(),
            ..._buildPlayers(),
          ],
        ),
      ),
    );
  }

  Widget _buildPitchLines() {
    return CustomPaint(
      size: Size.infinite,
      painter: PitchPainter(),
    );
  }

  List<Widget> _buildPlayers() {
    final parts = formation.split('-').map((e) => int.tryParse(e) ?? 0).toList();
    if (parts.isEmpty) return [];

    final List<Widget> widgets = [];
    final gk = players.where((p) => p.roleGroup == 'GK').toList();
    final defs = players.where((p) => p.roleGroup == 'DEF').toList();
    final mids = players.where((p) => p.roleGroup == 'MID').toList();
    final fwds = players.where((p) => p.roleGroup == 'FWD').toList();

    // GK always at bottom
    if (gk.isNotEmpty) {
      widgets.add(_positionedPlayer(gk[0], 0.5, 0.9));
    }

    if (parts.length == 3) {
      // Classic 3-part (e.g. 4-3-3, 4-4-2)
      final defCount = parts[0];
      final midCount = parts[1];
      final fwdCount = parts[2];

      _addRows(widgets, defs, defCount, 0.74);
      _addRows(widgets, mids, midCount, 0.5);
      _addRows(widgets, fwds, fwdCount, 0.22);
    } else if (parts.length == 4) {
      // 4-part (e.g. 4-2-3-1)
      final defCount = parts[0];
      final dmCount = parts[1];
      final amCount = parts[2];
      final fwdCount = parts[3];

      _addRows(widgets, defs, defCount, 0.76);
      
      // Split MIDs between DM and AM rows
      final dmPool = mids.take(dmCount).toList();
      final amPool = mids.skip(dmCount).take(amCount).toList();
      
      _addRows(widgets, dmPool, dmCount, 0.58);
      _addRows(widgets, amPool, amCount, 0.38);
      _addRows(widgets, fwds, fwdCount, 0.18);
    }

    return widgets;
  }

  void _addRows(List<Widget> widgets, List<MatchPreviewPlayer> pool, int count, double y) {
    for (int i = 0; i < count; i++) {
      if (i < pool.length) {
        final x = _distribute(i, count);
        widgets.add(_positionedPlayer(pool[i], x, y));
      }
    }
  }

  double _distribute(int index, int total) {
    if (total == 1) return 0.5;
    return 0.15 + (index * (0.7 / (total - 1)));
  }

  Widget _positionedPlayer(MatchPreviewPlayer p, double x, double y) {
    return Align(
      alignment: Alignment(x * 2 - 1, y * 2 - 1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorTokens.surface,
              border: Border.all(color: ColorTokens.accent, width: 2),
              boxShadow: [
                BoxShadow(
                  color: ColorTokens.accent.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(
                (p.predictedScore * 100).toStringAsFixed(0),
                style: TypographyTokens.headline.copyWith(
                  fontSize: 12,
                  color: ColorTokens.accent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              p.shortName.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Center line
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
    
    // Center circle
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width * 0.15, paint);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 2, paint..style = PaintingStyle.fill);

    // Penalty areas
    final boxW = size.width * 0.6;
    final boxH = size.height * 0.15;
    
    // Penalty areas - slightly offset from edges to avoid rounded corners overlap
    final pad = 4.0;
    
    // Bottom box
    canvas.drawRect(
      Rect.fromLTRB(size.width * 0.2, size.height * 0.82, size.width * 0.8, size.height - pad),
      paint..style = PaintingStyle.stroke,
    );
    
    // Top box
    canvas.drawRect(
      Rect.fromLTRB(size.width * 0.2, pad, size.width * 0.8, size.height * 0.18),
      paint..style = PaintingStyle.stroke,
    );

    // Penalty spots
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.88), 2, paint..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.12), 2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
