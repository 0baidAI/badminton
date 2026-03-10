// lib/providers/history_provider.dart
//
// Handles saving and loading match history.
// Uses SharedPreferences — this saves data to the PHONE's local storage,
// so history survives even when the app is closed and reopened.

import 'dart:convert'; // For JSON encoding/decoding
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/match_model.dart';

class HistoryProvider extends ChangeNotifier {
  List<MatchModel> _matches = [];

  // Getter — returns a read-only copy of the matches list
  List<MatchModel> get matches => List.unmodifiable(_matches);

  // The key used to store data in SharedPreferences (like a dictionary key)
  static const String _storageKey = 'match_history';

  // Constructor: automatically load history when the app starts
  HistoryProvider() {
    _loadFromStorage();
  }

  // ── Load history from phone storage ──────────────────────────────────
  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString != null) {
      // Decode the JSON string back into a list of MatchModel objects
      final List<dynamic> jsonList = json.decode(jsonString);
      _matches = jsonList.map((e) => MatchModel.fromJson(e)).toList();
      notifyListeners();
    }
  }

  // ── Save a new match to history ───────────────────────────────────────
  Future<void> addMatch(MatchModel match) async {
    _matches.insert(0, match); // Insert at front so newest appears first
    await _saveToStorage();
    notifyListeners();
  }

  // ── Clear all history ─────────────────────────────────────────────────
  Future<void> clearHistory() async {
    _matches.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    notifyListeners();
  }

  // ── Write current list to phone storage ──────────────────────────────
  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    // Convert list of MatchModel objects → JSON string → save
    final jsonString = json.encode(_matches.map((m) => m.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }
}
