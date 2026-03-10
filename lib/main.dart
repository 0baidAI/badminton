// lib/main.dart
// ── App Entry Point ───────────────────────────────────────────────────────
// This is the first file Flutter runs.
// We set up "Providers" here — think of them as shared data stores
// that any screen in the app can read from and write to.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/game_provider.dart';
import 'providers/history_provider.dart';
import 'providers/tournament_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    // MultiProvider wraps the whole app so ALL screens can access these providers
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => TournamentProvider()),
      ],
      child: const BadmintonApp(),
    ),
  );
}

class BadmintonApp extends StatelessWidget {
  const BadmintonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Badminton Score',
      debugShowCheckedModeBanner: false, // Removes the "debug" ribbon in top-right
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20), // Dark green
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
