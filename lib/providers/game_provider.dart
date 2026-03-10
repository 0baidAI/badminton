// lib/providers/game_provider.dart
//
// ════════════════════════════════════════════════════════
//  THIS IS THE "BRAIN" OF THE APP — READ THIS CAREFULLY!
// ════════════════════════════════════════════════════════
//
// BADMINTON SERVICE RULES (explained simply):
//
//  1. WHICH SIDE to serve from:
//     → Server's score is EVEN (0, 2, 4…)  → Serve from the RIGHT side
//     → Server's score is ODD  (1, 3, 5…)  → Serve from the LEFT side
//
//  2. WHEN to change server:
//     → The team that WINS a rally scores a point.
//     → If the SERVING team wins   → They keep serving (no change).
//     → If the RECEIVING team wins → They become the new server.
//
//  3. DOUBLES rotation (position swap):
//     → When your team wins a rally ON YOUR OWN SERVE, the two players
//       swap positions on the court.
//     → When your team wins by taking the serve from the opponent,
//       players do NOT swap — they stay in their half-court positions.

import 'package:flutter/material.dart';

// Enum: what kind of match is being played?
enum MatchMode { singles, doubles }

// Enum: which side of the court is the server standing on?
enum ServeSide { right, left }

class GameProvider extends ChangeNotifier {
  // ── Match Setup Variables ──────────────────────────────────────────────
  MatchMode matchMode = MatchMode.singles;
  int targetScore = 21;    // Win condition (e.g., first to 21)
  bool winBy2 = true;      // Must lead by 2 to win (deuce rule)

  // Team display names
  String team1Name = 'Team 1';
  String team2Name = 'Team 2';

  // Individual player names within each team (used for doubles)
  String team1Player1 = 'Player 1';
  String team1Player2 = 'Player 2';
  String team2Player1 = 'Player 3';
  String team2Player2 = 'Player 4';

  // ── Live Score Variables ───────────────────────────────────────────────
  int team1Score = 0;
  int team2Score = 0;

  // ── Service Tracking Variables ─────────────────────────────────────────
  // currentServer: 0 = team1 is serving | 1 = team2 is serving
  int currentServer = 0;

  // (Doubles only) Which player in the serving team is currently serving?
  // true = player 1 of that team | false = player 2 of that team
  bool serverIsPlayer1 = true;

  // (Doubles only) Have the players on each team swapped sides?
  bool team1Swapped = false;
  bool team2Swapped = false;

  // ── Game State ─────────────────────────────────────────────────────────
  bool gameOver = false;
  String? winnerName;

  // Undo history — stores a "snapshot" of game state before each point
  final List<Map<String, dynamic>> _history = [];

  // ══════════════════════════════════════════════════════════════════════
  //  COMPUTED GETTERS — these auto-calculate based on current state
  // ══════════════════════════════════════════════════════════════════════

  /// Rule 1: Which side does the server stand on?
  /// Even score → Right | Odd score → Left
  ServeSide get serveSide {
    int serverScore = currentServer == 0 ? team1Score : team2Score;
    return serverScore % 2 == 0 ? ServeSide.right : ServeSide.left;
  }

  /// Returns the name of the current server (specific player for doubles)
  String get currentServerName {
    if (matchMode == MatchMode.singles) {
      return currentServer == 0 ? team1Name : team2Name;
    }
    // Doubles: figure out WHICH player on the serving team is the server
    if (currentServer == 0) {
      // Check if team1's players have swapped
      if (!team1Swapped) {
        return serverIsPlayer1 ? team1Player1 : team1Player2;
      } else {
        return serverIsPlayer1 ? team1Player2 : team1Player1;
      }
    } else {
      if (!team2Swapped) {
        return serverIsPlayer1 ? team2Player1 : team2Player2;
      } else {
        return serverIsPlayer1 ? team2Player2 : team2Player1;
      }
    }
  }

  /// Returns the team name of who is currently serving
  String get currentServerTeamName =>
      currentServer == 0 ? team1Name : team2Name;

  // ══════════════════════════════════════════════════════════════════════
  //  WIN CONDITION LOGIC
  // ══════════════════════════════════════════════════════════════════════

  /// Check if a score is a winning score.
  ///
  /// Examples (target = 21, winBy2 = true):
  ///   21 vs 18 → WIN  (reached 21, lead by 3 ≥ 2)
  ///   21 vs 20 → NOT YET  (lead is only 1)
  ///   22 vs 20 → WIN  (deuce resolved, lead by 2)
  ///   30 vs 29 → WIN  (hit the score cap of target+9)
  bool _isWinner(int myScore, int opponentScore) {
    if (!winBy2) {
      // Simple rule: first to target wins
      return myScore >= targetScore;
    }
    // Deuce rule: must reach target AND lead by 2
    if (myScore >= targetScore && myScore - opponentScore >= 2) return true;

    // Score cap to prevent infinite games
    // In standard badminton: target=21 → cap=30 (21+9)
    // This formula works for 11→20, 15→24, 21→30
    int cap = targetScore + 9;
    if (myScore >= cap) return true; // Whoever reaches cap first wins

    return false;
  }

  // ══════════════════════════════════════════════════════════════════════
  //  MAIN SCORING ACTION
  // ══════════════════════════════════════════════════════════════════════

  /// Call this when a team scores a point.
  /// [team] = 0 (team 1 scored) or 1 (team 2 scored)
  void addPoint(int team) {
    if (gameOver) return; // Don't score after match is over

    // Save current state so we can undo this action
    _saveToHistory();

    // Was it the serving team that scored, or the receiving team?
    bool serverScored = (team == currentServer);

    // Increment the score for the team that won this rally
    if (team == 0) {
      team1Score++;
    } else {
      team2Score++;
    }

    if (serverScored) {
      // ── Case A: Serving team scored ───────────────────────────────────
      // Server KEEPS serving. No service change.
      // BUT in doubles, the two players on the scoring team SWAP positions.
      if (matchMode == MatchMode.doubles) {
        if (team == 0) {
          team1Swapped = !team1Swapped;
        } else {
          team2Swapped = !team2Swapped;
        }
      }
    } else {
      // ── Case B: Receiving team scored ─────────────────────────────────
      // Receiving team WINS the serve. Service changes to the scoring team.
      currentServer = team;
      // In doubles, the player who was in receiving position now serves first
      serverIsPlayer1 = true;
      // Note: players do NOT swap positions when service changes
    }

    // ── Check if anyone has won the match ─────────────────────────────
    int myScore = team == 0 ? team1Score : team2Score;
    int oppScore = team == 0 ? team2Score : team1Score;

    if (_isWinner(myScore, oppScore)) {
      gameOver = true;
      winnerName = team == 0 ? team1Name : team2Name;
    }

    notifyListeners(); // Tell the UI to refresh
  }

  // ── Undo last point ────────────────────────────────────────────────────
  void undoLastPoint() {
    if (_history.isEmpty) return;
    final last = _history.removeLast();
    // Restore all state from the saved snapshot
    team1Score = last['team1Score'];
    team2Score = last['team2Score'];
    currentServer = last['currentServer'];
    serverIsPlayer1 = last['serverIsPlayer1'];
    team1Swapped = last['team1Swapped'];
    team2Swapped = last['team2Swapped'];
    gameOver = last['gameOver'];
    winnerName = last['winnerName'];
    notifyListeners();
  }

  /// Save a snapshot of the current state to undo history
  void _saveToHistory() {
    _history.add({
      'team1Score': team1Score,
      'team2Score': team2Score,
      'currentServer': currentServer,
      'serverIsPlayer1': serverIsPlayer1,
      'team1Swapped': team1Swapped,
      'team2Swapped': team2Swapped,
      'gameOver': gameOver,
      'winnerName': winnerName,
    });
  }

  // ── Match Setup ────────────────────────────────────────────────────────
  void setupMatch({
    required String t1Name,
    required String t2Name,
    required int target,
    required bool by2,
    required MatchMode mode,
    String t1p1 = '',
    String t1p2 = '',
    String t2p1 = '',
    String t2p2 = '',
  }) {
    team1Name = t1Name;
    team2Name = t2Name;
    targetScore = target;
    winBy2 = by2;
    matchMode = mode;
    team1Player1 = t1p1.isNotEmpty ? t1p1 : t1Name;
    team1Player2 = t1p2;
    team2Player1 = t2p1.isNotEmpty ? t2p1 : t2Name;
    team2Player2 = t2p2;
    resetMatch();
  }

  void setInitialServer(int team) {
    currentServer = team;
    notifyListeners();
  }

  /// Reset all scores and server for a new match (keep settings)
  void resetMatch() {
    team1Score = 0;
    team2Score = 0;
    currentServer = 0;
    serverIsPlayer1 = true;
    team1Swapped = false;
    team2Swapped = false;
    gameOver = false;
    winnerName = null;
    _history.clear();
    notifyListeners();
  }
}
