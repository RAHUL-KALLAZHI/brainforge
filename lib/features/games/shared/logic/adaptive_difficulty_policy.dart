import 'package:flutter/foundation.dart';
import '../domain/adaptation_action.dart';
import '../domain/adaptation_decision.dart';
import '../domain/adaptive_policy_config.dart';
import '../domain/game_attempt.dart';
import '../domain/game_difficulty.dart';
import '../domain/game_status.dart';

/// Pure-Dart deterministic evaluation policy for dynamic game difficulty adaptation.
class AdaptiveDifficultyPolicy {
  final AdaptivePolicyConfig config;

  const AdaptiveDifficultyPolicy({
    this.config = AdaptivePolicyConfig.standard,
  });

  /// Evaluates recent gameplay attempts to recommend the next [GameDifficulty].
  ///
  /// This evaluation is pure, deterministic, and bounded:
  /// - Only completed and failed attempts are eligible for performance evaluation.
  /// - Abandoned sessions are excluded as they represent user departure rather than evaluated skill.
  /// - A minimum of [config.minRequiredAttempts] eligible attempts is required before adjusting difficulty.
  /// - Adjustments are strictly limited to $\pm 1$ level per evaluation.
  /// - Level 10 cannot be promoted; Level 1 cannot be demoted.
  AdaptationDecision evaluate({
    required GameDifficulty currentDifficulty,
    required List<GameAttempt> recentAttempts,
  }) {
    // 1. Filter eligible attempts at currentDifficulty and sort latest-first to ensure deterministic ordering
    final eligibleAttempts = recentAttempts
        .where((a) =>
            (a.status == GameStatus.completed ||
                a.status == GameStatus.failed) &&
            a.difficultyLevel == currentDifficulty.level)
        .toList()
      ..sort((a, b) {
        final cmp = b.completedAt.compareTo(a.completedAt);
        return cmp != 0 ? cmp : b.id.compareTo(a.id);
      });

    // 2. Bound to the configured rolling window size
    final window = eligibleAttempts.take(config.windowSize).toList();

    // Count consecutive qualifying wins at currentDifficulty (latest first)
    int consecutiveWins = 0;
    for (final attempt in eligibleAttempts) {
      if (attempt.status == GameStatus.completed &&
          attempt.accuracy >= config.promotionAccuracyThreshold) {
        consecutiveWins++;
      } else {
        break;
      }
    }

    // Check consecutive recent failures (from latest backward)
    int consecutiveFailures = 0;
    for (final attempt in window) {
      if (attempt.status == GameStatus.failed) {
        consecutiveFailures++;
      } else {
        break;
      }
    }

    // 3. Early demotion check: Repeated consecutive failures (>= consecutiveFailuresForDemotion)
    final hasConsecutiveFailures =
        consecutiveFailures >= config.consecutiveFailuresForDemotion;
    if (hasConsecutiveFailures) {
      if (currentDifficulty.level <= GameDifficulty.minLevel) {
        final decision = AdaptationDecision(
          targetDifficulty: currentDifficulty,
          previousDifficulty: currentDifficulty,
          action: AdaptationAction.maintain,
          reason: 'Minimum difficulty level reached (Level 1).',
          evaluatedAttemptsCount: window.length,
          qualifyingWinsCount: 0,
        );
        _logDecision(decision);
        return decision;
      }
      final decision = AdaptationDecision(
        targetDifficulty: currentDifficulty.decrease(1),
        previousDifficulty: currentDifficulty,
        action: AdaptationAction.demote,
        reason: 'Difficulty adjusted to help you progress.',
        evaluatedAttemptsCount: window.length,
        qualifyingWinsCount: 0,
      );
      _logDecision(decision);
      return decision;
    }

    // 4. Check for insufficient history at current difficulty
    if (window.length < config.minRequiredAttempts) {
      final decision = AdaptationDecision.insufficientData(
        currentDifficulty: currentDifficulty,
        availableCount: window.length,
        requiredCount: config.minRequiredAttempts,
        qualifyingWinsCount: consecutiveWins,
      );
      _logDecision(decision);
      return decision;
    }

    // 5. Compute metrics across the rolling window
    double totalAccuracy = 0.0;
    int validAccuracyCount = 0;
    for (final attempt in window) {
      if (!attempt.accuracy.isNaN && !attempt.accuracy.isInfinite) {
        totalAccuracy += attempt.accuracy.clamp(0.0, 1.0);
        validAccuracyCount++;
      }
    }

    final avgAccuracy =
        validAccuracyCount > 0 ? (totalAccuracy / validAccuracyCount) : 0.0;

    // 6. Evaluate Promotion criteria:
    // Qualifying promotion window consists of the [config.minRequiredAttempts] most recent attempts at this level.
    // - Every attempt in this qualifying promotion window must be completed (no failures/timeouts).
    // - Average accuracy across this qualifying window must meet or exceed promotionAccuracyThreshold.
    final qualifyingPromotionWindow =
        window.take(config.minRequiredAttempts).toList();
    final allCompletedInQualifyingWindow = qualifyingPromotionWindow
        .every((a) => a.status == GameStatus.completed);

    double qualifyingAccuracySum = 0.0;
    int validQualifyingCount = 0;
    for (final attempt in qualifyingPromotionWindow) {
      if (!attempt.accuracy.isNaN && !attempt.accuracy.isInfinite) {
        qualifyingAccuracySum += attempt.accuracy.clamp(0.0, 1.0);
        validQualifyingCount++;
      }
    }
    final qualifyingAvgAccuracy = validQualifyingCount > 0
        ? (qualifyingAccuracySum / validQualifyingCount)
        : 0.0;

    if (qualifyingAvgAccuracy >= config.promotionAccuracyThreshold &&
        allCompletedInQualifyingWindow) {
      if (currentDifficulty.level >= GameDifficulty.maxLevel) {
        final decision = AdaptationDecision(
          targetDifficulty: currentDifficulty,
          previousDifficulty: currentDifficulty,
          action: AdaptationAction.maintain,
          reason: 'Maximum difficulty level reached (Level 10).',
          averageAccuracy: qualifyingAvgAccuracy,
          evaluatedAttemptsCount: qualifyingPromotionWindow.length,
          qualifyingWinsCount: consecutiveWins,
        );
        _logDecision(decision);
        return decision;
      }

      final decision = AdaptationDecision(
        targetDifficulty: currentDifficulty.increase(1),
        previousDifficulty: currentDifficulty,
        action: AdaptationAction.promote,
        reason: "Difficulty increased — you're performing consistently well.",
        averageAccuracy: qualifyingAvgAccuracy,
        evaluatedAttemptsCount: qualifyingPromotionWindow.length,
        qualifyingWinsCount: consecutiveWins,
      );
      _logDecision(decision);
      return decision;
    }

    // 7. Evaluate Demotion criteria based on window accuracy:
    final isLowAccuracy = avgAccuracy < config.demotionAccuracyThreshold;

    if (isLowAccuracy) {
      if (currentDifficulty.level <= GameDifficulty.minLevel) {
        final decision = AdaptationDecision(
          targetDifficulty: currentDifficulty,
          previousDifficulty: currentDifficulty,
          action: AdaptationAction.maintain,
          reason: 'Minimum difficulty level reached (Level 1).',
          averageAccuracy: avgAccuracy,
          evaluatedAttemptsCount: window.length,
          qualifyingWinsCount: 0,
        );
        _logDecision(decision);
        return decision;
      }

      final decision = AdaptationDecision(
        targetDifficulty: currentDifficulty.decrease(1),
        previousDifficulty: currentDifficulty,
        action: AdaptationAction.demote,
        reason: 'Difficulty adjusted to help you progress.',
        averageAccuracy: avgAccuracy,
        evaluatedAttemptsCount: window.length,
        qualifyingWinsCount: 0,
      );
      _logDecision(decision);
      return decision;
    }

    // 8. Performance within normal expected bounds: maintain level
    final decision = AdaptationDecision(
      targetDifficulty: currentDifficulty,
      previousDifficulty: currentDifficulty,
      action: AdaptationAction.maintain,
      reason: 'Difficulty maintained based on steady performance.',
      averageAccuracy: avgAccuracy,
      evaluatedAttemptsCount: window.length,
      qualifyingWinsCount: consecutiveWins,
    );
    _logDecision(decision);
    return decision;
  }

  void _logDecision(AdaptationDecision decision) {
    debugPrint(
      '[AdaptiveDifficultyPolicy] Decision: action=${decision.action.name}, '
      'previous=L${decision.previousDifficulty.level}, '
      'target=L${decision.targetDifficulty.level}, '
      'reason="${decision.reason}", '
      'avgAccuracy=${decision.averageAccuracy != null ? (decision.averageAccuracy! * 100).toStringAsFixed(1) : "N/A"}%, '
      'evaluatedCount=${decision.evaluatedAttemptsCount}',
    );
  }
}
