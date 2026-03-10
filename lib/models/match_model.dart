// lib/models/match_model.dart
// Stores the result of a completed match (used for history)
// Now supports both normal matches AND tournament matches.

class MatchModel {
  final String id;
  final String team1;
  final String team2;
  final int team1Score;
  final int team2Score;
  final String winner;
  final DateTime dateTime;
  final int targetScore;
  final bool winBy2;
  final String matchMode;       // 'singles' or 'doubles'

  // ── Tournament fields (null = normal match) ──────────────────────────
  final bool isTournament;      // true if this match was part of a tournament
  final String? tournamentRound;// e.g. "Quarterfinals", "Final", "Round 1"

  MatchModel({
    required this.id,
    required this.team1,
    required this.team2,
    required this.team1Score,
    required this.team2Score,
    required this.winner,
    required this.dateTime,
    required this.targetScore,
    required this.winBy2,
    required this.matchMode,
    this.isTournament = false,
    this.tournamentRound,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'team1': team1,
        'team2': team2,
        'team1Score': team1Score,
        'team2Score': team2Score,
        'winner': winner,
        'dateTime': dateTime.toIso8601String(),
        'targetScore': targetScore,
        'winBy2': winBy2,
        'matchMode': matchMode,
        'isTournament': isTournament,
        'tournamentRound': tournamentRound,
      };

  factory MatchModel.fromJson(Map<String, dynamic> json) => MatchModel(
        id: json['id'],
        team1: json['team1'],
        team2: json['team2'],
        team1Score: json['team1Score'],
        team2Score: json['team2Score'],
        winner: json['winner'],
        dateTime: DateTime.parse(json['dateTime']),
        targetScore: json['targetScore'],
        winBy2: json['winBy2'],
        matchMode: json['matchMode'],
        isTournament: json['isTournament'] ?? false,
        tournamentRound: json['tournamentRound'],
      );
}