import 'package:equatable/equatable.dart';

/// Configuration thresholds and rolling window constraints for the adaptive difficulty policy.
class AdaptivePolicyConfig extends Equatable {
  /// Number of recent eligible attempts evaluated in the rolling window.
  final int windowSize;

  /// Minimum number of eligible attempts required before making an adaptation decision.
  final int minRequiredAttempts;

  /// Average accuracy (0.0 to 1.0) required across the window to trigger a difficulty promotion.
  final double promotionAccuracyThreshold;

  /// Average accuracy (0.0 to 1.0) below which difficulty is demoted.
  final double demotionAccuracyThreshold;

  /// Number of consecutive failures that trigger a demotion even if the full window is not complete.
  final int consecutiveFailuresForDemotion;

  const AdaptivePolicyConfig({
    this.windowSize = 5,
    this.minRequiredAttempts = 3,
    this.promotionAccuracyThreshold = 0.90,
    this.demotionAccuracyThreshold = 0.60,
    this.consecutiveFailuresForDemotion = 2,
  })  : assert(windowSize >= minRequiredAttempts,
            'windowSize must be >= minRequiredAttempts'),
        assert(minRequiredAttempts >= 1, 'minRequiredAttempts must be >= 1'),
        assert(
          promotionAccuracyThreshold >= 0.0 &&
              promotionAccuracyThreshold <= 1.0,
          'promotionAccuracyThreshold must be between 0.0 and 1.0',
        ),
        assert(
          demotionAccuracyThreshold >= 0.0 && demotionAccuracyThreshold <= 1.0,
          'demotionAccuracyThreshold must be between 0.0 and 1.0',
        ),
        assert(
          promotionAccuracyThreshold > demotionAccuracyThreshold,
          'promotionAccuracyThreshold must exceed demotionAccuracyThreshold',
        ),
        assert(
          consecutiveFailuresForDemotion >= 1,
          'consecutiveFailuresForDemotion must be >= 1',
        );

  /// Default baseline configuration for BrainForge cognitive games.
  static const AdaptivePolicyConfig standard = AdaptivePolicyConfig();

  @override
  List<Object?> get props => [
        windowSize,
        minRequiredAttempts,
        promotionAccuracyThreshold,
        demotionAccuracyThreshold,
        consecutiveFailuresForDemotion,
      ];
}
