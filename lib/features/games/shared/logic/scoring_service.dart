import '../domain/game_score.dart';

/// Service computing standardized, explainable scores across all mini-games.
///
/// Implements the formula:
/// $\text{Score} = \text{round}(1000 \times (0.70 \times \text{Accuracy} + 0.20 \times \text{Efficiency} + 0.10 \times \text{Completion}))$
class ScoringService {
  const ScoringService();

  /// Calculates a [GameScore] with bounded, normalized components.
  GameScore calculateScore({
    required int correctCount,
    required int incorrectCount,
    int missedCount = 0,
    required int completedRounds,
    required int targetRounds,
    required Duration totalResponseTime,
    Duration targetResponseTime = const Duration(seconds: 2),
    Duration maxResponseTime = const Duration(seconds: 10),
    bool isAbandoned = false,
  }) {
    if (isAbandoned) {
      return GameScore.zero(
        correctCount: correctCount,
        incorrectCount: incorrectCount,
        missedCount: missedCount,
        duration: totalResponseTime,
        isAbandoned: true,
      );
    }

    final totalOpportunities = correctCount + incorrectCount + missedCount;
    if (totalOpportunities <= 0) {
      return GameScore.zero(
        correctCount: 0,
        incorrectCount: 0,
        missedCount: 0,
        duration: totalResponseTime,
      );
    }

    // 1. Accuracy (0.0 to 1.0)
    final rawAccuracy = correctCount / totalOpportunities;
    final accuracy = rawAccuracy.clamp(0.0, 1.0);

    // 2. Completion (0.0 to 1.0)
    final completion = targetRounds > 0
        ? (completedRounds / targetRounds).clamp(0.0, 1.0)
        : 0.0;

    // 3. Efficiency (0.0 to 1.0) based on average latency per opportunity
    final avgResponseTimeMs = totalOpportunities > 0
        ? totalResponseTime.inMilliseconds / totalOpportunities
        : maxResponseTime.inMilliseconds.toDouble();

    final targetMs = targetResponseTime.inMilliseconds.toDouble();
    final maxMs = maxResponseTime.inMilliseconds.toDouble();

    double rawEfficiency;
    if (avgResponseTimeMs <= targetMs) {
      rawEfficiency = 1.0;
    } else if (avgResponseTimeMs >= maxMs) {
      rawEfficiency = 0.0;
    } else {
      rawEfficiency = (maxMs - avgResponseTimeMs) / (maxMs - targetMs);
    }

    // Guard: Speed must NEVER reward incorrect answers excessively.
    // Scale efficiency by accuracy so rapid guessing cannot yield high scores.
    final efficiency = (rawEfficiency * accuracy).clamp(0.0, 1.0);

    // Weighted Score
    final weighted =
        (0.70 * accuracy) + (0.20 * efficiency) + (0.10 * completion);
    final scaledScore = (weighted * 1000).round().clamp(0, 1000);

    return GameScore(
      accuracy: accuracy,
      efficiency: efficiency,
      completion: completion,
      scaledScore: scaledScore,
      correctCount: correctCount,
      incorrectCount: incorrectCount,
      missedCount: missedCount,
      duration: totalResponseTime,
      isAbandoned: false,
    );
  }
}
