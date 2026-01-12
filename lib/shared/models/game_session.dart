import 'package:equatable/equatable.dart';

/// Represents a completed game session with score data
class GameSession extends Equatable {
  const GameSession({
    required this.id,
    required this.score,
    required this.lettersCompleted,
    required this.wordsCompleted,
    required this.timestamp,
    this.isWinner = false,
  });

  /// Unique identifier for this session
  final String id;

  /// Total score achieved
  final int score;

  /// Number of letters completed (out of 25)
  final int lettersCompleted;

  /// Total words submitted during the game
  final int wordsCompleted;

  /// When the game was played
  final DateTime timestamp;

  /// Whether the player completed all 25 letters
  final bool isWinner;

  @override
  List<Object?> get props => [
        id,
        score,
        lettersCompleted,
        wordsCompleted,
        timestamp,
        isWinner,
      ];

  /// Create from JSON map
  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      id: json['id'] as String,
      score: json['score'] as int,
      lettersCompleted: json['lettersCompleted'] as int,
      wordsCompleted: json['wordsCompleted'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isWinner: json['isWinner'] as bool? ?? false,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'score': score,
      'lettersCompleted': lettersCompleted,
      'wordsCompleted': wordsCompleted,
      'timestamp': timestamp.toIso8601String(),
      'isWinner': isWinner,
    };
  }

  /// Create a new GameSession with current timestamp
  factory GameSession.create({
    required int score,
    required int lettersCompleted,
    required int wordsCompleted,
    required bool isWinner,
  }) {
    return GameSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      score: score,
      lettersCompleted: lettersCompleted,
      wordsCompleted: wordsCompleted,
      timestamp: DateTime.now(),
      isWinner: isWinner,
    );
  }
}
