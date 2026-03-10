// lib/screens/home_screen.dart
// The main menu / home screen of the app

import 'package:flutter/material.dart';
import 'match_setup_screen.dart';
import 'history_screen.dart';
import 'tournament_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Green gradient background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B5E20), Color(0xFF004D40)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── App Logo & Title ──────────────────────────────
                  const Text('🏸', style: TextStyle(fontSize: 72)),
                  const SizedBox(height: 8),
                  const Text(
                    'Badminton',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Text(
                    'Score & Tournament',
                    style: TextStyle(fontSize: 17, color: Colors.white70),
                  ),
                  const SizedBox(height: 56),

                  // ── Main Menu Buttons ─────────────────────────────
                  _HomeButton(
                    emoji: '🎯',
                    label: 'New Match',
                    subtitle: 'Singles or Doubles',
                    color: const Color(0xFF388E3C),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MatchSetupScreen()),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _HomeButton(
                    emoji: '🏆',
                    label: 'Tournament',
                    subtitle: 'Generate bracket & standings',
                    color: const Color(0xFFE65100),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TournamentScreen()),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _HomeButton(
                    emoji: '📋',
                    label: 'Match History',
                    subtitle: 'View past results',
                    color: const Color(0xFF1565C0),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    ),
                  ),

                  const SizedBox(height: 48),
                  const Text(
                    'Tap a side to score a point',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Reusable Big Button Widget ────────────────────────────────────────────
class _HomeButton extends StatelessWidget {
  final String emoji;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _HomeButton({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      subtitle,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white54, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}