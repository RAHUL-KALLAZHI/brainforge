import 'package:equatable/equatable.dart';
import 'adaptation_action.dart';
import 'game_difficulty.dart';

/// Immutable evaluation result produced by the adaptive difficulty policy.
class AdaptationDecision extends Equatable {
  /// The recommended difficulty level for the next session.
  final GameDifficulty targetDifficulty;

  /// The difficulty level evaluated during the session.
  final GameDifficulty previousDifficulty;

  /// The adaptation action category.
  final AdaptationAction action;

  /// Human-readable, explainable rationale for the decision.
  final String reason;

  /// Average accuracy computed across the evaluated eligible window, if applicable.
  final double? averageAccuracy;

  /// Number of eligible attempts evaluated.
  final int evaluatedAttemptsCount;

  /// Number of consecutive qualifying wins achieved at the current difficulty.
  final int qualifyingWinsCount;

  const AdaptationDecision({
    required this.targetDifficulty,
    required this.previousDifficulty,
    required this.action,
    required this.reason,
    this.averageAccuracy,
    this.evaluatedAttemptsCount = 0,
    this.qualifyingWinsCount = 0,
  });

  /// Factory creating an initial/baseline decision when history is insufficient.
  factory AdaptationDecision.insufficientData({
    required GameDifficulty currentDifficulty,
    required int availableCount,
    required int requiredCount,
    int qualifyingWinsCount = 0,
    String? reason,
  }) {
    return AdaptationDecision(
      targetDifficulty: currentDifficulty,
      previousDifficulty: currentDifficulty,
      action: AdaptationAction.insufficientData,
      reason: reason ??
          (qualifyingWinsCount > 0
              ? '$qualifyingWinsCount of $requiredCount consecutive wins at Level ${currentDifficulty.level}. Win $requiredCount with ≥90% accuracy to promote.'
              : 'Keep practising to personalize your difficulty.'),
      evaluatedAttemptsCount: availableCount,
      qualifyingWinsCount: qualifyingWinsCount,
    );
  }

  /// Whether this decision resulted in an effective difficulty level change.
  bool get hasDifficultyChanged =>
      targetDifficulty.level != previousDifficulty.level;

  @override
  List<Object?> get props => [
        targetDifficulty,
        previousDifficulty,
        action,
        reason,
        averageAccuracy,
        evaluatedAttemptsCount,
        qualifyingWinsCount,
      ];

  @override
  String toString() =>
      'AdaptationDecision($action: ${previousDifficulty.level} -> ${targetDifficulty.level}, reason: "$reason")';
}
