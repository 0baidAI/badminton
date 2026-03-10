// lib/screens/scoring_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/game_provider.dart';
import '../providers/history_provider.dart';
import '../models/match_model.dart';

class ScoringScreen extends StatefulWidget {
  const ScoringScreen({super.key});

  @override
  State<ScoringScreen> createState() => _ScoringScreenState();
}

class _ScoringScreenState extends State<ScoringScreen> {
  // Flash message shown briefly after each point
  // e.g. "✓ Alice keeps serve!" or "🔄 Serve → Bob!"
  String? _flashMessage;
  Color _flashColor = Colors.green;
  Timer? _flashTimer;

  // Track the previous server so we can detect a change
  int? _prevServer;

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  // Called after addPoint — shows a brief flash message
  void _showFlash(String message, Color color) {
    _flashTimer?.cancel();
    setState(() {
      _flashMessage = message;
      _flashColor = color;
    });
    // Hide the message after 1.5 seconds
    _flashTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _flashMessage = null);
    });
  }

  // Tap handler: score a point and show appropriate flash
  void _onTap(BuildContext context, int team) {
    final game = context.read<GameProvider>();
    if (game.gameOver) return;

    // Remember who was serving BEFORE the point
    final serverBefore = game.currentServer;
    final serverNameBefore = game.currentServerName;

    game.addPoint(team);

    // Check if server changed AFTER the point
    final serverAfter = game.currentServer;

    if (serverAfter != serverBefore) {
      // Service changed → receiving team scored
      _showFlash(
        '🔄 Serve → ${game.currentServerName}!',
        Colors.orange.shade700,
      );
    } else {
      // Server STAYS — serving team scored
      _showFlash(
        '✅ $serverNameBefore keeps serve!',
        Colors.green.shade700,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();

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
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo Last Point',
            onPressed: game.gameOver ? null : () => game.undoLastPoint(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Service bar ──────────────────────────────────────────────
          _ServiceBar(game: game),

          // ── Flash message (briefly shown after each point) ───────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _flashMessage != null
                ? Container(
                    key: ValueKey(_flashMessage),
                    width: double.infinity,
                    color: _flashColor,
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Text(
                      _flashMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  )
                : const SizedBox(key: ValueKey('empty'), height: 0),
          ),

          // ── Split scoring panels ─────────────────────────────────────
          Expanded(
            child: Row(
              children: [
                // LEFT → Team 1
                Expanded(
                  child: GestureDetector(
                    onTap: game.gameOver
                        ? null
                        : () => _onTap(context, 0),
                    child: _ScorePanel(
                      teamName: game.team1Name,
                      score: game.team1Score,
                      isServing: game.currentServer == 0,
                      serveSide: game.currentServer == 0
                          ? game.serveSide
                          : null,
                      color: const Color(0xFF1B5E20),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),

                Container(width: 2, color: Colors.white12),

                // RIGHT → Team 2
                Expanded(
                  child: GestureDetector(
                    onTap: game.gameOver
                        ? null
                        : () => _onTap(context, 1),
                    child: _ScorePanel(
                      teamName: game.team2Name,
                      score: game.team2Score,
                      isServing: game.currentServer == 1,
                      serveSide: game.currentServer == 1
                          ? game.serveSide
                          : null,
                      color: const Color(0xFF0D47A1),
                      alignment: Alignment.centerRight,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom info bar ──────────────────────────────────────────
          _BottomBar(game: game),
        ],
      ),
    );
  }

  void _showWinnerDialog(BuildContext context, GameProvider game) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    color: game.winnerName == game.team1Name
                        ? Colors.green
                        : Colors.white38,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('—',
                      style:
                          TextStyle(fontSize: 32, color: Colors.grey)),
                ),
                Text(
                  '${game.team2Score}',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    color: game.winnerName == game.team2Name
                        ? Colors.blue
                        : Colors.white38,
                  ),
                ),
              ],
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.home),
            label: const Text('Save & Exit'),
            onPressed: () {
              _saveMatch(context, game);
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
          ),
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
          matchMode: game.matchMode == MatchMode.singles
              ? 'singles'
              : 'doubles',
        ));
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  SERVICE BAR — Shows clearly WHO is serving and from which side
// ════════════════════════════════════════════════════════════════════════════
class _ServiceBar extends StatelessWidget {
  final GameProvider game;
  const _ServiceBar({required this.game});

  @override
  Widget build(BuildContext context) {
    final serverName = game.currentServerName;
    final isRight = game.serveSide == ServeSide.right;
    final sideText = isRight ? 'Right side ▶' : '◀ Left side';

    return Container(
      color: const Color(0xFF1B5E20),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          // Shuttlecock icon
          const Text('🏸', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),

          // Server name — this is the MOST important thing to see clearly
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // WHO is serving
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Server: ',
                        style: TextStyle(
                            color: Colors.white60, fontSize: 12),
                      ),
                      TextSpan(
                        text: serverName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // WHERE they serve from
                Text(
                  sideText,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),

          // Serve side pill badge (right or left)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.yellow.shade700,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isRight ? '▶ RIGHT' : 'LEFT ◀',
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  SCORE PANEL
// ════════════════════════════════════════════════════════════════════════════
class _ScorePanel extends StatelessWidget {
  final String teamName;
  final int score;
  final bool isServing;
  final ServeSide? serveSide;
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
    final panelColor =
        isServing ? color : color.withOpacity(0.35);

    return Container(
      color: panelColor,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Team name
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

              // Big score number
              Text(
                '$score',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 96,
                    fontWeight: FontWeight.bold,
                    height: 1.0),
              ),

              // SERVING badge — only visible on the serving team's panel
              if (isServing) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '🏸  SERVING',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],

              // Dimmed "RECEIVING" badge on the non-serving side
              if (!isServing) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'RECEIVING',
                    style: TextStyle(
                      color: Colors.white30,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // "TAP TO SCORE" hint
          Positioned(
            top: 16,
            child: Text(
              'TAP TO SCORE',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.2),
                  fontSize: 11),
            ),
          ),

          // Serve-side dot — only on serving team's panel
          if (isServing && serveSide != null)
            Positioned(
              bottom: 20,
              left: _showDotOnLeft(alignment, serveSide!) ? 12 : null,
              right: _showDotOnLeft(alignment, serveSide!) ? null : 12,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.yellow.withOpacity(0.85),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    serveSide == ServeSide.right ? '▶' : '◀',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _showDotOnLeft(Alignment panelAlignment, ServeSide side) {
    if (panelAlignment == Alignment.centerLeft) {
      return side == ServeSide.left;
    }
    return side == ServeSide.right;
  }
}

// ── Bottom info bar ──────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final GameProvider game;
  const _BottomBar({required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A2F1A),
      padding:
          const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _chip('🎯 Target: ${game.targetScore}'),
          _chip(game.winBy2 ? '⚖️ Win by 2' : '🚫 No deuce'),
          _chip(game.matchMode == MatchMode.singles
              ? '👤 Singles'
              : '👥 Doubles'),
        ],
      ),
    );
  }

  Widget _chip(String text) => Text(
        text,
        style: const TextStyle(color: Colors.white54, fontSize: 13),
      );
}