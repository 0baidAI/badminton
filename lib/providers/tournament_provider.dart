// lib/providers/tournament_provider.dart
//
// Manages tournament brackets.
// Round naming (from the END of the bracket):
//   reverseIndex 0 → "Final"
//   reverseIndex 1 → "Semifinals"
//   reverseIndex 2 → "Quarterfinals"
//   reverseIndex 3+ → "Round 1", "Round 2", "Round 3" … (from the front)

import 'dart:math';
import 'package:flutter/material.dart';
import '../models/player.dart';

class TournamentMatch {
  final String id;
  String team1;
  String team2;
  String? winner;
  int? team1Score;
  int? team2Score;
  bool isCompleted;

  TournamentMatch({
    required this.id,
    required this.team1,
    required this.team2,
    this.winner,
    this.team1Score,
    this.team2Score,
    this.isCompleted = false,
  });
}

class TournamentProvider extends ChangeNotifier {
  List<Player> players = [];
  bool isDoubles = false;
  bool tournamentStarted = false;
  String? champion;

  // Match settings used in every live scoring screen
  int targetScore = 21;
  bool winBy2 = true;

  // Total expected rounds — calculated ONCE when tournament starts.
  // Used so round names don't change as rounds are generated.
  int totalExpectedRounds = 1;

  List<List<TournamentMatch>> rounds = [];

  // ── Round naming ─────────────────────────────────────────────────────
  // Called with roundIndex (0-based from the front).
  // Uses totalExpectedRounds so names are stable from round 1 onward.
  String roundNameFor(int roundIndex) {
    final reverseIndex = totalExpectedRounds - 1 - roundIndex;
    switch (reverseIndex) {
      case 0:
        return 'Final';
      case 1:
        return 'Semifinals';
      case 2:
        return 'Quarterfinals';
      default:
        // "Round 1", "Round 2", "Round 3" … for all earlier rounds
        return 'Round ${roundIndex + 1}';
    }
  }

  // ── Set up players ────────────────────────────────────────────────────
  void setPlayers(List<Player> p, {bool doubles = false}) {
    players = List.from(p);
    isDoubles = doubles;
    notifyListeners();
  }

  // ── Start tournament ──────────────────────────────────────────────────
  void startTournament({
    List<String>? firstMatchOverride,
    int target = 21,
    bool by2 = true,
  }) {
    targetScore = target;
    winBy2 = by2;

    final shuffled = List<Player>.from(players)..shuffle(Random());

    // Build team names
    List<String> teams = [];
    if (isDoubles) {
      for (int i = 0; i + 1 < shuffled.length; i += 2) {
        teams.add('${shuffled[i].name} & ${shuffled[i + 1].name}');
      }
    } else {
      teams = shuffled.map((p) => p.name).toList();
    }

    // Apply first-match override
    if (firstMatchOverride != null && firstMatchOverride.length == 2) {
      teams.removeWhere(
          (t) => t == firstMatchOverride[0] || t == firstMatchOverride[1]);
      teams = [firstMatchOverride[0], firstMatchOverride[1], ...teams];
    }

    // Calculate total expected rounds = ceil(log2(teams.length))
    // Examples: 2→1, 3-4→2, 5-8→3, 9-16→4, 17-32→5
    totalExpectedRounds = teams.length <= 1
        ? 1
        : (log(teams.length) / log(2)).ceil();

    // Build round 1
    List<TournamentMatch> firstRound = [];
    for (int i = 0; i < teams.length - 1; i += 2) {
      firstRound.add(TournamentMatch(
        id: 'r0_m${i ~/ 2}',
        team1: teams[i],
        team2: teams[i + 1],
      ));
    }
    if (teams.length.isOdd) {
      firstRound.add(TournamentMatch(
        id: 'r0_bye',
        team1: teams.last,
        team2: 'BYE',
        winner: teams.last,
        isCompleted: true,
      ));
    }

    rounds = [firstRound];
    tournamentStarted = true;
    champion = null;
    notifyListeners();
  }

  // ── Record result and auto-generate next round if needed ──────────────
  void recordResult(
      int roundIndex, int matchIndex, String winner, int score1, int score2) {
    final match = rounds[roundIndex][matchIndex];
    match.winner = winner;
    match.team1Score = score1;
    match.team2Score = score2;
    match.isCompleted = true;

    final roundComplete = rounds[roundIndex].every((m) => m.isCompleted);
    if (roundComplete) {
      _generateNextRound(roundIndex);
    }

    notifyListeners();
  }

  void _generateNextRound(int completedRoundIndex) {
    final winners =
        rounds[completedRoundIndex].map((m) => m.winner!).toList();

    if (winners.length == 1) {
      champion = winners[0];
      notifyListeners();
      return;
    }

    List<TournamentMatch> nextRound = [];
    for (int i = 0; i + 1 < winners.length; i += 2) {
      nextRound.add(TournamentMatch(
        id: 'r${completedRoundIndex + 1}_m${i ~/ 2}',
        team1: winners[i],
        team2: winners[i + 1],
      ));
    }
    if (winners.length.isOdd) {
      nextRound.add(TournamentMatch(
        id: 'r${completedRoundIndex + 1}_bye',
        team1: winners.last,
        team2: 'BYE',
        winner: winners.last,
        isCompleted: true,
      ));
    }

    rounds.add(nextRound);
    notifyListeners();
  }

  void resetTournament() {
    rounds = [];
    tournamentStarted = false;
    champion = null;
    totalExpectedRounds = 1;
    notifyListeners();
  }
}