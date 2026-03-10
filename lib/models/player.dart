// lib/models/player.dart
// Represents a single player in the app

class Player {
  final String id;   // Unique ID (e.g., "abc123")
  final String name; // Display name (e.g., "Alice")

  Player({required this.id, required this.name});

  // Convert Player to a Map (for saving to storage)
  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  // Create a Player from a saved Map (for loading from storage)
  factory Player.fromJson(Map<String, dynamic> json) =>
      Player(id: json['id'] as String, name: json['name'] as String);

  @override
  String toString() => name;
}
