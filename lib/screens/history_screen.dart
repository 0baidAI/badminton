// lib/screens/history_screen.dart
// Shows a list of all past matches saved to the phone

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/history_provider.dart';
import '../models/match_model.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match History'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          // Show clear button only if there are matches to clear
          if (history.matches.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear All History',
              onPressed: () => _confirmClear(context, history),
            ),
        ],
      ),
      body: history.matches.isEmpty
          ? _emptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: history.matches.length,
              itemBuilder: (ctx, i) =>
                  _MatchTile(match: history.matches[i]),
            ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('📋', style: TextStyle(fontSize: 64)),
          SizedBox(height: 16),
          Text('No matches yet!',
              style: TextStyle(fontSize: 20, color: Colors.grey)),
          SizedBox(height: 8),
          Text('Play a match and it will appear here.',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, HistoryProvider history) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear All History?'),
        content: const Text('This will permanently delete all match records.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              history.clearHistory();
              Navigator.pop(context);
            },
            child: const Text('Clear All',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Single match record card ──────────────────────────────────────────────
class _MatchTile extends StatelessWidget {
  final MatchModel match;
  const _MatchTile({required this.match});

  @override
  Widget build(BuildContext context) {
    final team1Won = match.winner == match.team1;

    // Format date simply without the 'intl' package
    final dt = match.dateTime;
    final dateStr =
        '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // Score row
            Row(
              children: [
                // Team 1 name (green if winner)
                Expanded(
                  child: Text(
                    match.team1,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: team1Won ? Colors.green.shade400 : null,
                    ),
                  ),
                ),

                // Score display
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${match.team1Score}  —  ${match.team2Score}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                // Team 2 name (green if winner)
                Expanded(
                  child: Text(
                    match.team2,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: !team1Won ? Colors.green.shade400 : null,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Meta info row
            Row(
              children: [
                const Text('🏆 ', style: TextStyle(fontSize: 13)),
                Text(match.winner,
                    style: TextStyle(
                        color: Colors.amber.shade400,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const Spacer(),
                // Match mode badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: match.matchMode == 'singles'
                        ? Colors.blue.shade900
                        : Colors.orange.shade900,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(match.matchMode,
                      style: const TextStyle(fontSize: 11, color: Colors.white70)),
                ),
                const SizedBox(width: 8),
                Text(dateStr,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
