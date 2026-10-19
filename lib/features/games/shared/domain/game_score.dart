import 'package:equatable/equatable.dart';

/// Immutable model representing normalized scoring calculations.
///
/// Formula:
/// $\text{Score} = \text{round}(1000 \times (0.70 \times \text{Accuracy} + 0.20 \times \text{Efficiency} + 0.10 \times \text{Completion}))$
class GameScore extends Equatable {
  final double accuracy;
  final double efficiency;
  final double completion;
  final int scaledScore;
  final int correctCount;
  final int incorrectCount;
  final int missedCount;
  final Duration duration;
  final bool isAbandoned;

  const GameScore({
    required this.accuracy,
    required this.efficiency,
    required this.completion,
    required this.scaledScore,
    required this.correctCount,
    required this.incorrectCount,
    required this.missedCount,
    required this.duration,
    this.isAbandoned = false,
  });

  /// Factory producing a zero score for abandoned or unattempted sessions.
  factory GameScore.zero({
    int correctCount = 0,
    int incorrectCount = 0,
    int missedCount = 0,
    Duration duration = Duration.zero,
    bool isAbandoned = false,
  }) {
    return GameScore(
      accuracy: 0.0,
      efficiency: 0.0,
      completion: 0.0,
      scaledScore: 0,
      correctCount: correctCount,
      incorrectCount: incorrectCount,
      missedCount: missedCount,
      duration: duration,
      isAbandoned: isAbandoned,
    );
  }

  @override
  List<Object?> get props => [
        accuracy,
        efficiency,
        completion,
        scaledScore,
        correctCount,
        incorrectCount,
        missedCount,
        duration,
        isAbandoned,
      ];
}
