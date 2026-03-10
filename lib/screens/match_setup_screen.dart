// lib/screens/match_setup_screen.dart
// Screen where players configure a match before playing

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'scoring_screen.dart';

class MatchSetupScreen extends StatefulWidget {
  const MatchSetupScreen({super.key});

  @override
  State<MatchSetupScreen> createState() => _MatchSetupScreenState();
}

class _MatchSetupScreenState extends State<MatchSetupScreen> {
  // Text controllers for player name inputs
  final _t1p1 = TextEditingController(text: 'Player 1');
  final _t1p2 = TextEditingController(text: 'Player 2');
  final _t2p1 = TextEditingController(text: 'Player 3');
  final _t2p2 = TextEditingController(text: 'Player 4');

  int _targetScore = 21;          // Default target score
  bool _winBy2 = true;            // Deuce rule on by default
  MatchMode _matchMode = MatchMode.singles; // Default: singles
  int _initialServer = 0;         // 0 = team1 serves first

  @override
  void dispose() {
    // Clean up controllers when the screen is removed
    _t1p1.dispose();
    _t1p2.dispose();
    _t2p1.dispose();
    _t2p2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDoubles = _matchMode == MatchMode.doubles;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Setup'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Match Mode ──────────────────────────────────────────
            _sectionTitle('Match Mode'),
            SegmentedButton<MatchMode>(
              segments: const [
                ButtonSegment(
                    value: MatchMode.singles,
                    label: Text('Singles (1v1)'),
                    icon: Icon(Icons.person)),
                ButtonSegment(
                    value: MatchMode.doubles,
                    label: Text('Doubles (2v2)'),
                    icon: Icon(Icons.group)),
              ],
              selected: {_matchMode},
              onSelectionChanged: (v) =>
                  setState(() => _matchMode = v.first),
            ),
            const SizedBox(height: 24),

            // ── Player Names ────────────────────────────────────────
            _sectionTitle(isDoubles ? 'Team 1 Players' : 'Player 1'),
            _nameField(_t1p1,
                hint: isDoubles ? 'Team 1 — Player A' : 'Player 1 Name'),
            if (isDoubles) ...[
              const SizedBox(height: 8),
              _nameField(_t1p2, hint: 'Team 1 — Player B'),
            ],
            const SizedBox(height: 20),

            _sectionTitle(isDoubles ? 'Team 2 Players' : 'Player 2'),
            _nameField(_t2p1,
                hint: isDoubles ? 'Team 2 — Player A' : 'Player 2 Name'),
            if (isDoubles) ...[
              const SizedBox(height: 8),
              _nameField(_t2p2, hint: 'Team 2 — Player B'),
            ],
            const SizedBox(height: 24),

            // ── Target Score ────────────────────────────────────────
            _sectionTitle('Target Score'),
            Wrap(
              spacing: 10,
              children: [11, 15, 21].map((score) {
                return ChoiceChip(
                  label: Text('$score points',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _targetScore == score
                              ? Colors.white
                              : null)),
                  selected: _targetScore == score,
                  onSelected: (_) => setState(() => _targetScore = score),
                  selectedColor: const Color(0xFF388E3C),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Deuce / Win-by-2 Rule ───────────────────────────────
            Card(
              child: SwitchListTile(
                title: const Text('Win by 2 Points (Deuce)'),
                subtitle: Text(
                  _winBy2
                      ? 'Must lead by 2 points to win. Max: ${_targetScore + 9}'
                      : 'First to $_targetScore wins (no deuce)',
                  style: const TextStyle(fontSize: 13),
                ),
                value: _winBy2,
                onChanged: (v) => setState(() => _winBy2 = v),
                activeColor: const Color(0xFF388E3C),
              ),
            ),
            const SizedBox(height: 20),

            // ── Who Serves First ────────────────────────────────────
            _sectionTitle('Who Serves First?'),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<int>(
                    title: Text(
                      isDoubles ? 'Team 1' : _t1p1.text,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    value: 0,
                    groupValue: _initialServer,
                    onChanged: (v) => setState(() => _initialServer = v!),
                    activeColor: const Color(0xFF388E3C),
                  ),
                ),
                Expanded(
                  child: RadioListTile<int>(
                    title: Text(
                      isDoubles ? 'Team 2' : _t2p1.text,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    value: 1,
                    groupValue: _initialServer,
                    onChanged: (v) => setState(() => _initialServer = v!),
                    activeColor: const Color(0xFF388E3C),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Start Button ────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startMatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF388E3C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('🏸  Start Match',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Helper: Section header text
  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          title,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
              letterSpacing: 0.5),
        ),
      );

  // Helper: Text input field
  Widget _nameField(TextEditingController c, {required String hint}) =>
      TextField(
        controller: c,
        decoration: InputDecoration(
          hintText: hint,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        onChanged: (_) => setState(() {}), // Refresh to update radio labels
      );

  // Called when "Start Match" is pressed
  void _startMatch() {
    final game = context.read<GameProvider>();
    final isDoubles = _matchMode == MatchMode.doubles;

    // Build full team name strings
    String t1Name = isDoubles
        ? '${_t1p1.text} & ${_t1p2.text}'
        : _t1p1.text;
    String t2Name = isDoubles
        ? '${_t2p1.text} & ${_t2p2.text}'
        : _t2p1.text;

    // Configure the game provider with our settings
    game.setupMatch(
      t1Name: t1Name,
      t2Name: t2Name,
      target: _targetScore,
      by2: _winBy2,
      mode: _matchMode,
      t1p1: _t1p1.text,
      t1p2: _t1p2.text,
      t2p1: _t2p1.text,
      t2p2: _t2p2.text,
    );
    game.setInitialServer(_initialServer);

    // Navigate to the scoring screen
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ScoringScreen()));
  }
}
