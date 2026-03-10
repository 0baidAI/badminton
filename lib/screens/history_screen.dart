// lib/screens/history_screen.dart
// Shows ALL past matches — both normal and tournament matches.
// Tournament matches show an orange "🏆 Tournament · Round name" badge.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/history_provider.dart';
import '../models/match_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Filter: 'all' | 'normal' | 'tournament'
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();

    // Apply filter
    final filtered = history.matches.where((m) {
      if (_filter == 'normal') return !m.isTournament;
      if (_filter == 'tournament') return m.isTournament;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match History'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          if (history.matches.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear All History',
              onPressed: () => _confirmClear(context, history),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Filter tabs ─────────────────────────────────────────────
          if (history.matches.isNotEmpty)
            Container(
              color: const Color(0xFF0D1F3C),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _FilterChip(
                      label: 'All',
                      selected: _filter == 'all',
                      onTap: () => setState(() => _filter = 'all')),
                  const SizedBox(width: 8),
                  _FilterChip(
                      label: '🎯 Normal',
                      selected: _filter == 'normal',
                      onTap: () => setState(() => _filter = 'normal')),
                  const SizedBox(width: 8),
                  _FilterChip(
                      label: '🏆 Tournament',
                      selected: _filter == 'tournament',
                      onTap: () => setState(() => _filter = 'tournament')),
                ],
              ),
            ),

          // ── Match list ──────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? _emptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) =>
                        _MatchTile(match: filtered[i]),
                  ),
          ),
        ],
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
        content: const Text(
            'This will permanently delete all match records.'),
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

// ── Filter chip button ────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF1565C0)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF42A5F5)
                : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 13,
              fontWeight:
                  selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? Colors.white : Colors.white60),
        ),
      ),
    );
  }
}

// ── Single match card ─────────────────────────────────────────────────────
class _MatchTile extends StatelessWidget {
  final MatchModel match;
  const _MatchTile({required this.match});

  @override
  Widget build(BuildContext context) {
    final team1Won = match.winner == match.team1;
    final dt = match.dateTime;
    final dateStr =
        '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // Orange border for tournament matches, default for normal
        side: match.isTournament
            ? const BorderSide(color: Color(0xFFE65100), width: 1.2)
            : BorderSide.none,
      ),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Tournament banner (only for tournament matches) ──────
            if (match.isTournament) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE65100).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFFE65100).withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🏆 Tournament',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF8A65))),
                    if (match.tournamentRound != null) ...[
                      const Text('  ·  ',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 12)),
                      Text(match.tournamentRound!,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFFCC80))),
                    ],
                  ],
                ),
              ),
            ],

            // ── Score row ────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    match.team1,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color:
                          team1Won ? Colors.green.shade400 : null,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
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
                Expanded(
                  child: Text(
                    match.team2,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color:
                          !team1Won ? Colors.green.shade400 : null,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // ── Meta row ─────────────────────────────────────────────
            Row(
              children: [
                const Text('🏆 ', style: TextStyle(fontSize: 13)),
                Text(match.winner,
                    style: TextStyle(
                        color: Colors.amber.shade400,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const Spacer(),
                // Mode badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: match.matchMode == 'singles'
                        ? Colors.blue.shade900
                        : Colors.orange.shade900,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(match.matchMode,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white70)),
                ),
                const SizedBox(width: 8),
                Text(dateStr,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}