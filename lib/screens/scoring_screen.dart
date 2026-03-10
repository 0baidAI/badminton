// lib/screens/scoring_screen.dart
//
// ══════════════════════════════════════════════════════
//  THE SCORING SCREEN — Main gameplay UI
// ══════════════════════════════════════════════════════
// Layout:
//   [  Service Info Bar  ]   ← shows who is serving & from which side
//   [         |         ]
//   [ Team 1  |  Team 2 ]   ← tap LEFT side to score for team1
//   [ Score   |  Score  ]     tap RIGHT side to score for team2
//   [         |         ]
//   [  Match Info Bar   ]   ← shows target, rules, mode

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/game_provider.dart';
import '../providers/history_provider.dart';
import '../models/match_model.dart';

class ScoringScreen extends StatelessWidget {
  const ScoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();

    // When the game ends, show a winner dialog on the next frame
    if (game.gameOver) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showWinnerDialog(context, game);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: const Text('Match'),
        actions: [
          // Undo button
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo Last Point',
            onPressed: game.gameOver ? null : () => game.undoLastPoint(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Top bar: who is serving and from which side ────────────
          _ServiceBar(game: game),

          // ── Main area: two tappable score panels ───────────────────
          Expanded(
            child: Row(
              children: [
                // LEFT side → Team 1 scores when tapped
                Expanded(
                  child: GestureDetector(
                    onTap: game.gameOver ? null : () => game.addPoint(0),
                    child: _ScorePanel(
                      teamName: game.team1Name,
                      score: game.team1Score,
                      isServing: game.currentServer == 0,
                      serveSide: game.currentServer == 0 ? game.serveSide : null,
                      color: const Color(0xFF1B5E20),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),

                // Vertical divider between the two sides
                Container(width: 2, color: Colors.white12),

                // RIGHT side → Team 2 scores when tapped
                Expanded(
                  child: GestureDetector(
                    onTap: game.gameOver ? null : () => game.addPoint(1),
                    child: _ScorePanel(
                      teamName: game.team2Name,
                      score: game.team2Score,
                      isServing: game.currentServer == 1,
                      serveSide: game.currentServer == 1 ? game.serveSide : null,
                      color: const Color(0xFF0D47A1),
                      alignment: Alignment.centerRight,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom info bar ─────────────────────────────────────────
          _BottomBar(game: game),
        ],
      ),
    );
  }

  // Show winner dialog when match is over
  void _showWinnerDialog(BuildContext context, GameProvider game) {
    // Check if dialog is already showing (avoid duplicates)
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false, // User must press a button
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🏆 Match Over!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${game.winnerName} wins!',
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${game.team1Score}',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    color: game.currentServer == 0
                        ? Colors.green
                        : Colors.white54,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('—',
                      style: TextStyle(fontSize: 32, color: Colors.grey)),
                ),
                Text(
                  '${game.team2Score}',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    color: game.currentServer == 1
                        ? Colors.blue
                        : Colors.white54,
                  ),
                ),
              ],
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          // Exit → save match and go back to home
          TextButton.icon(
            icon: const Icon(Icons.home),
            label: const Text('Save & Exit'),
            onPressed: () {
              _saveMatch(context, game);
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop(); // Back to setup screen
            },
          ),
          // Play Again → reset scores, same players
          ElevatedButton.icon(
            icon: const Icon(Icons.replay),
            label: const Text('Play Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF388E3C),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              _saveMatch(context, game);
              game.resetMatch();
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      ),
    );
  }

  // Save completed match to history
  void _saveMatch(BuildContext context, GameProvider game) {
    if (!context.mounted) return;
    context.read<HistoryProvider>().addMatch(MatchModel(
          id: const Uuid().v4(),
          team1: game.team1Name,
          team2: game.team2Name,
          team1Score: game.team1Score,
          team2Score: game.team2Score,
          winner: game.winnerName ?? '',
          dateTime: DateTime.now(),
          targetScore: game.targetScore,
          winBy2: game.winBy2,
          matchMode:
              game.matchMode == MatchMode.singles ? 'singles' : 'doubles',
        ));
  }
}

// ── Service Bar ────────────────────────────────────────────────────────────
// Shows: who is serving | which court side | serve side indicator
class _ServiceBar extends StatelessWidget {
  final GameProvider game;
  const _ServiceBar({required this.game});

  @override
  Widget build(BuildContext context) {
    final side =
        game.serveSide == ServeSide.right ? 'Right ▶' : '◀ Left';
    return Container(
      color: const Color(0xFF2E7D32),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏸', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Serving: ${game.currentServerName}  ·  Side: $side',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Score Panel (one side of the court) ────────────────────────────────────
class _ScorePanel extends StatelessWidget {
  final String teamName;
  final int score;
  final bool isServing;
  final ServeSide? serveSide; // Only set if this team is serving
  final Color color;
  final Alignment alignment;

  const _ScorePanel({
    required this.teamName,
    required this.score,
    required this.isServing,
    required this.color,
    required this.alignment,
    this.serveSide,
  });

  @override
  Widget build(BuildContext context) {
    // Serving team is brighter; receiving team is dimmed
    final panelColor = isServing ? color : color.withOpacity(0.35);

    return Container(
      color: panelColor,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Main content: name + score ────────────────────────────
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Team/Player name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  teamName,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),

              // SCORE — big number
              Text(
                '$score',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 96,
                    fontWeight: FontWeight.bold,
                    height: 1.0),
              ),

              // "SERVING" badge
              if (isServing) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '🏸 SERVING',
                    style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
              ],
            ],
          ),

          // ── "TAP TO SCORE" hint at the top ───────────────────────
          Positioned(
            top: 16,
            child: Text(
              'TAP TO SCORE',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.25), fontSize: 11),
            ),
          ),

          // ── Serve-side indicator dot (bottom corner) ─────────────
          if (isServing && serveSide != null)
            Positioned(
              bottom: 20,
              // Position based on: which side is this panel? + which side to serve from?
              left: _showOnLeft(alignment, serveSide!) ? 12 : null,
              right: _showOnLeft(alignment, serveSide!) ? null : 12,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.yellow.withOpacity(0.85),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    serveSide == ServeSide.right ? '▶' : '◀',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Should the indicator dot appear on the LEFT of this panel?
  bool _showOnLeft(Alignment panelAlignment, ServeSide side) {
    // For Team 1 (left panel): right serve = right side of panel = right edge
    if (panelAlignment == Alignment.centerLeft) {
      return side == ServeSide.left;
    }
    // For Team 2 (right panel): right serve = left side of panel (closer to net)
    return side == ServeSide.right;
  }
}

// ── Bottom Info Bar ─────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final GameProvider game;
  const _BottomBar({required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A2F1A),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _infoChip('🎯 Target: ${game.targetScore}'),
          _infoChip(game.winBy2 ? '⚖️ Win by 2' : '🚫 No deuce'),
          _infoChip(
              game.matchMode == MatchMode.singles ? '👤 Singles' : '👥 Doubles'),
        ],
      ),
    );
  }

  Widget _infoChip(String text) => Text(
        text,
        style:
            const TextStyle(color: Colors.white54, fontSize: 13),
      );
}
