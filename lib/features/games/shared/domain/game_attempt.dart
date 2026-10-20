import 'package:equatable/equatable.dart';
import 'game_result.dart';
import 'game_status.dart';

/// Immutable record of a game attempt for historical and analytics persistence.
class GameAttempt extends Equatable {
  final String id;
  final String gameId;
  final int difficultyLevel;
  final GameStatus status;
  final int finalScore;
  final double accuracy;
  final int correctCount;
  final int incorrectCount;
  final int missedCount;
  final List<int> responseTimesMs;
  final DateTime startedAt;
  final DateTime completedAt;
  final int? seed;

  const GameAttempt({
    required this.id,
    required this.gameId,
    required this.difficultyLevel,
    required this.status,
    required this.finalScore,
    required this.accuracy,
    required this.correctCount,
    required this.incorrectCount,
    required this.missedCount,
    required this.responseTimesMs,
    required this.startedAt,
    required this.completedAt,
    this.seed,
  });

  /// Factory converting a completed [GameResult] into a persistent [GameAttempt].
  factory GameAttempt.fromResult({
    required String id,
    required GameResult result,
    required List<int> responseTimesMs,
  }) {
    return GameAttempt(
      id: id,
      gameId: result.gameId,
      difficultyLevel: result.difficulty.level,
      status: result.status,
      finalScore: result.score.scaledScore,
      accuracy: result.score.accuracy,
      correctCount: result.score.correctCount,
      incorrectCount: result.score.incorrectCount,
      missedCount: result.score.missedCount,
      responseTimesMs: List.unmodifiable(responseTimesMs),
      startedAt: result.startedAt,
      completedAt: result.completedAt,
      seed: result.seed,
    );
  }

  /// Creates a copy of this [GameAttempt] with updated fields.
  GameAttempt copyWith({
    String? id,
    String? gameId,
    int? difficultyLevel,
    GameStatus? status,
    int? finalScore,
    double? accuracy,
    int? correctCount,
    int? incorrectCount,
    int? missedCount,
    List<int>? responseTimesMs,
    DateTime? startedAt,
    DateTime? completedAt,
    int? seed,
  }) {
    return GameAttempt(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      status: status ?? this.status,
      finalScore: finalScore ?? this.finalScore,
      accuracy: accuracy ?? this.accuracy,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      missedCount: missedCount ?? this.missedCount,
      responseTimesMs: responseTimesMs ?? this.responseTimesMs,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      seed: seed ?? this.seed,
    );
  }

  /// Median response time in milliseconds, or null if no attempts recorded.
  int? get medianResponseTimeMs {
    if (responseTimesMs.isEmpty) return null;
    final sorted = List<int>.from(responseTimesMs)..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) {
      return sorted[middle];
    }
    return ((sorted[middle - 1] + sorted[middle]) / 2).round();
  }

  @override
  List<Object?> get props => [
        id,
        gameId,
        difficultyLevel,
        status,
        finalScore,
        accuracy,
        correctCount,
        incorrectCount,
        missedCount,
        responseTimesMs,
        startedAt,
        completedAt,
        seed,
      ];
}
