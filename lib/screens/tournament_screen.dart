// lib/screens/tournament_screen.dart
//
// ALL CHANGES IN THIS VERSION:
//  1. Round naming is correct:
//       Earlier rounds  → "Round 1", "Round 2", "Round 3" …
//       3rd from last   → "Quarterfinals"
//       2nd from last   → "Semifinals"
//       Last round      → "Final"
//     The names are STABLE because totalExpectedRounds is calculated
//     at tournament start from the player count.
//
//  2. Tapping a match opens the FULL tap-to-score screen —
//     same split-screen UI with service bar, serve-side dot, undo.
//     NO manual score entry at all.
//
//  3. Every completed match is saved to Match History automatically.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/tournament_provider.dart';
import '../providers/history_provider.dart';
import '../models/player.dart';
import '../models/match_model.dart';

class TournamentScreen extends StatefulWidget {
  const TournamentScreen({super.key});

  @override
  State<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends State<TournamentScreen> {
  final List<TextEditingController> _controllers = [
    TextEditingController(text: 'Alice'),
    TextEditingController(text: 'Bob'),
    TextEditingController(text: 'Charlie'),
    TextEditingController(text: 'Diana'),
  ];
  bool _isDoubles = false;
  int _targetScore = 21;
  bool _winBy2 = true;

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tournament = context.watch<TournamentProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆 Tournament'),
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
        actions: [
          if (tournament.tournamentStarted)
            TextButton.icon(
              onPressed: () => _confirmReset(context, tournament),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Reset',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: tournament.tournamentStarted
          ? _BracketView(tournament: tournament)
          : _buildSetupView(context),
    );
  }

  // ── Setup Screen ────────────────────────────────────────────────────────
  Widget _buildSetupView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Doubles toggle
          Card(
            child: SwitchListTile(
              title: const Text('Doubles Tournament'),
              subtitle: const Text('Players are paired into teams of 2'),
              value: _isDoubles,
              onChanged: (v) => setState(() => _isDoubles = v),
              activeColor: const Color(0xFFE65100),
            ),
          ),
          const SizedBox(height: 12),

          // Target score
          const Text('Target Score',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: [11, 15, 21].map((s) {
              return ChoiceChip(
                label: Text('$s pts',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _targetScore == s ? Colors.white : null)),
                selected: _targetScore == s,
                onSelected: (_) => setState(() => _targetScore = s),
                selectedColor: const Color(0xFFE65100),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Win by 2
          Card(
            child: SwitchListTile(
              title: const Text('Win by 2 (Deuce)'),
              value: _winBy2,
              onChanged: (v) => setState(() => _winBy2 = v),
              activeColor: const Color(0xFFE65100),
            ),
          ),
          const SizedBox(height: 12),

          // Players list header
          Row(
            children: [
              const Text('Players',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton.outlined(
                icon: const Icon(Icons.remove),
                onPressed: _controllers.length > 2
                    ? () => setState(
                        () => _controllers.removeLast().dispose())
                    : null,
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                icon: const Icon(Icons.add),
                onPressed: () => setState(() => _controllers.add(
                    TextEditingController(
                        text: 'Player ${_controllers.length + 1}'))),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Expanded(
            child: ListView.builder(
              itemCount: _controllers.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: _controllers[i],
                  decoration: InputDecoration(
                    labelText: 'Player ${i + 1}',
                    prefixIcon: const Icon(Icons.person),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _controllers.length >= 2
                  ? () => _startTournament(context)
                  : null,
              icon: const Icon(Icons.emoji_events),
              label: const Text('Generate Bracket',
                  style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE65100),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startTournament(BuildContext context) {
    final tournament = context.read<TournamentProvider>();
    final players = _controllers
        .where((c) => c.text.trim().isNotEmpty)
        .map((c) =>
            Player(id: const Uuid().v4(), name: c.text.trim()))
        .toList();

    if (players.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Need at least 2 players!')));
      return;
    }

    tournament.setPlayers(players, doubles: _isDoubles);
    tournament.startTournament(target: _targetScore, by2: _winBy2);
  }

  void _confirmReset(
      BuildContext context, TournamentProvider tournament) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Tournament?'),
        content: const Text('All match results will be lost.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              tournament.resetTournament();
              Navigator.pop(context);
            },
            child:
                const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  BRACKET VIEW
// ════════════════════════════════════════════════════════════════════════════
class _BracketView extends StatelessWidget {
  final TournamentProvider tournament;
  const _BracketView({required this.tournament});

  Color _badgeColor(String roundName) {
    switch (roundName) {
      case 'Final':
        return const Color(0xFFFFD700);       // Gold
      case 'Semifinals':
        return const Color(0xFFC0C0C0);       // Silver
      case 'Quarterfinals':
        return const Color(0xFFCD7F32);       // Bronze
      default:
        return const Color(0xFFE65100);       // Orange — Round 1, 2, 3…
    }
  }

  @override
  Widget build(BuildContext context) {
    if (tournament.champion != null) {
      return _ChampionScreen(champion: tournament.champion!);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tournament.rounds.length,
      itemBuilder: (_, roundIndex) {
        final round = tournament.rounds[roundIndex];
        // Use provider's stable naming method
        final roundName = tournament.roundNameFor(roundIndex);
        final badgeColor = _badgeColor(roundName);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Round header badge
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.15),
                border:
                    Border.all(color: badgeColor.withOpacity(0.6)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (roundName == 'Final')
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Text('🏆',
                          style: TextStyle(fontSize: 14)),
                    ),
                  Text(
                    roundName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Match cards
            ...round.asMap().entries.map((entry) {
              final matchIndex = entry.key;
              final match = entry.value;
              return _MatchCard(
                match: match,
                onTap: match.isCompleted
                    ? null
                    : () => _openLiveScoring(context, tournament,
                        roundIndex, matchIndex, match, roundName),
              );
            }),

            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  // Opens the full tap-to-score screen — NO manual entry
  void _openLiveScoring(
    BuildContext context,
    TournamentProvider tournament,
    int roundIndex,
    int matchIndex,
    TournamentMatch match,
    String roundName,
  ) {
    final historyProvider = context.read<HistoryProvider>();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TournamentScoringScreen(
          match: match,
          roundName: roundName,
          targetScore: tournament.targetScore,
          winBy2: tournament.winBy2,
          onMatchComplete: (winner, s1, s2) {
            // 1. Save result back to bracket
            tournament.recordResult(
                roundIndex, matchIndex, winner, s1, s2);

            // 2. Save to Match History automatically
            historyProvider.addMatch(MatchModel(
              id: const Uuid().v4(),
              team1: match.team1,
              team2: match.team2,
              team1Score: s1,
              team2Score: s2,
              winner: winner,
              dateTime: DateTime.now(),
              targetScore: tournament.targetScore,
              winBy2: tournament.winBy2,
              matchMode: tournament.isDoubles ? 'doubles' : 'singles',
              isTournament: true,
              tournamentRound: roundName,
            ));
          },
        ),
      ),
    );
  }
}

// ── Match card in bracket ────────────────────────────────────────────────────
class _MatchCard extends StatelessWidget {
  final TournamentMatch match;
  final VoidCallback? onTap;
  const _MatchCard({required this.match, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: match.isCompleted ? 1 : 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: match.isCompleted
                    ? Colors.green.shade700
                    : Colors.orange.shade800,
                child: Icon(
                  match.isCompleted
                      ? Icons.check
                      : Icons.sports_tennis,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${match.team1}  vs  ${match.team2}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    match.isCompleted
                        ? Text(
                            '🏆 ${match.winner}  ·  ${match.team1Score} – ${match.team2Score}',
                            style: TextStyle(
                                color: Colors.green.shade400,
                                fontSize: 13))
                        : const Text(
                            '🏸 Tap to play this match',
                            style: TextStyle(
                                color: Colors.orange,
                                fontSize: 13)),
                  ],
                ),
              ),
              if (!match.isCompleted)
                const Icon(Icons.chevron_right,
                    color: Colors.orange),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  TOURNAMENT SCORING SCREEN
//  Identical tap-to-score split-screen as the normal ScoringScreen.
//  No manual score input — just tap left or right side to score.
// ════════════════════════════════════════════════════════════════════════════

enum _ServeSide { right, left }

class TournamentScoringScreen extends StatefulWidget {
  final TournamentMatch match;
  final String roundName;
  final int targetScore;
  final bool winBy2;
  final void Function(String winner, int score1, int score2)
      onMatchComplete;

  const TournamentScoringScreen({
    super.key,
    required this.match,
    required this.roundName,
    required this.targetScore,
    required this.winBy2,
    required this.onMatchComplete,
  });

  @override
  State<TournamentScoringScreen> createState() =>
      _TournamentScoringScreenState();
}

class _TournamentScoringScreenState
    extends State<TournamentScoringScreen> {
  int _score1 = 0;
  int _score2 = 0;
  int _server = 0; // 0 = team1 serves, 1 = team2 serves
  bool _gameOver = false;
  String? _winner;
  bool _dialogShown = false;

  // Undo stack
  final List<Map<String, dynamic>> _history = [];

  // ── Serve side: even score → Right, odd → Left ───────────────────────
  _ServeSide get _serveSide {
    final serverScore = _server == 0 ? _score1 : _score2;
    return serverScore % 2 == 0 ? _ServeSide.right : _ServeSide.left;
  }

  // ── Win check ────────────────────────────────────────────────────────
  bool _isWinner(int my, int opp) {
    if (!widget.winBy2) return my >= widget.targetScore;
    final cap = widget.targetScore + 9;
    if (my >= cap) return true;
    return my >= widget.targetScore && my - opp >= 2;
  }

  // ── Score a point ─────────────────────────────────────────────────────
  void _addPoint(int team) {
    if (_gameOver) return;
    _history.add({
      's1': _score1, 's2': _score2,
      'server': _server, 'gameOver': _gameOver, 'winner': _winner,
    });
    setState(() {
      final serverScored = team == _server;
      if (team == 0) _score1++; else _score2++;
      if (!serverScored) _server = team;
      final my = team == 0 ? _score1 : _score2;
      final opp = team == 0 ? _score2 : _score1;
      if (_isWinner(my, opp)) {
        _gameOver = true;
        _winner =
            team == 0 ? widget.match.team1 : widget.match.team2;
      }
    });
  }

  // ── Undo ──────────────────────────────────────────────────────────────
  void _undo() {
    if (_history.isEmpty) return;
    final prev = _history.removeLast();
    setState(() {
      _score1 = prev['s1'];
      _score2 = prev['s2'];
      _server = prev['server'];
      _gameOver = prev['gameOver'];
      _winner = prev['winner'];
      _dialogShown = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show winner dialog once after game ends
    if (_gameOver && !_dialogShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_dialogShown && mounted) {
          _dialogShown = true;
          _showWinnerDialog();
        }
      });
    }

    final sideLabel =
        _serveSide == _ServeSide.right ? 'Right ▶' : '◀ Left';
    final serverName =
        _server == 0 ? widget.match.team1 : widget.match.team2;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.match.team1}  vs  ${widget.match.team2}',
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.roundName,
              style: const TextStyle(
                  fontSize: 11, color: Colors.white60),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo last point',
            onPressed: _gameOver || _history.isEmpty ? null : _undo,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Service bar ───────────────────────────────────────────
          Container(
            color: const Color(0xFF2E7D32),
            padding: const EdgeInsets.symmetric(
                vertical: 10, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🏸',
                    style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Serving: $serverName  ·  Side: $sideLabel',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // ── Split score panels — TAP TO SCORE ─────────────────────
          Expanded(
            child: Row(
              children: [
                // LEFT panel → Team 1
                Expanded(
                  child: GestureDetector(
                    onTap: _gameOver ? null : () => _addPoint(0),
                    child: _ScorePanel(
                      teamName: widget.match.team1,
                      score: _score1,
                      isServing: _server == 0,
                      serveSide:
                          _server == 0 ? _serveSide : null,
                      color: const Color(0xFF1B5E20),
                      isLeft: true,
                    ),
                  ),
                ),
                Container(width: 2, color: Colors.white12),
                // RIGHT panel → Team 2
                Expanded(
                  child: GestureDetector(
                    onTap: _gameOver ? null : () => _addPoint(1),
                    child: _ScorePanel(
                      teamName: widget.match.team2,
                      score: _score2,
                      isServing: _server == 1,
                      serveSide:
                          _server == 1 ? _serveSide : null,
                      color: const Color(0xFF0D47A1),
                      isLeft: false,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom info bar ───────────────────────────────────────
          Container(
            color: const Color(0xFF1A2F1A),
            padding: const EdgeInsets.symmetric(
                vertical: 10, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('🎯 Target: ${widget.targetScore}',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 13)),
                Text(
                    widget.winBy2
                        ? '⚖️ Win by 2'
                        : '🚫 No deuce',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 13)),
                Text('🏆 ${widget.roundName}',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showWinnerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('🏸 Match Over!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_winner advances! 🎉',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$_score1',
                    style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: _winner == widget.match.team1
                            ? Colors.green
                            : Colors.white38)),
                const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12),
                  child: Text('—',
                      style: TextStyle(
                          fontSize: 32, color: Colors.grey)),
                ),
                Text('$_score2',
                    style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: _winner == widget.match.team2
                            ? Colors.blue
                            : Colors.white38)),
              ],
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle),
            label: const Text('Save & Return to Bracket'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              widget.onMatchComplete(_winner!, _score1, _score2);
              Navigator.of(context).pop();  // close dialog
              Navigator.of(context).pop();  // back to bracket
            },
          ),
        ],
      ),
    );
  }
}

// ── Score panel widget (identical to main ScoringScreen) ───────────────────
class _ScorePanel extends StatelessWidget {
  final String teamName;
  final int score;
  final bool isServing;
  final _ServeSide? serveSide;
  final Color color;
  final bool isLeft;

  const _ScorePanel({
    required this.teamName,
    required this.score,
    required this.isServing,
    required this.color,
    required this.isLeft,
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
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8),
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

          // "TAP TO SCORE" hint
          Positioned(
            top: 16,
            child: Text(
              'TAP TO SCORE',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.25),
                  fontSize: 11),
            ),
          ),

          // Serve-side dot
          if (isServing && serveSide != null)
            Positioned(
              bottom: 20,
              left: _dotLeft(isLeft, serveSide!) ? 12 : null,
              right: _dotLeft(isLeft, serveSide!) ? null : 12,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.yellow.withOpacity(0.85),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    serveSide == _ServeSide.right ? '▶' : '◀',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _dotLeft(bool panelIsLeft, _ServeSide side) {
    if (panelIsLeft) return side == _ServeSide.left;
    return side == _ServeSide.right;
  }
}

// ── Champion screen ──────────────────────────────────────────────────────────
class _ChampionScreen extends StatelessWidget {
  final String champion;
  const _ChampionScreen({required this.champion});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏆',
                style: TextStyle(fontSize: 96)),
            const SizedBox(height: 16),
            const Text(
              'CHAMPION!',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                  color: Colors.amber),
            ),
            const SizedBox(height: 16),
            Text(
              champion,
              style: const TextStyle(
                  fontSize: 36, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            const Text(
              'Congratulations! 🎉',
              style: TextStyle(
                  fontSize: 18, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}