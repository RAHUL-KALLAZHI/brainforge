/// Action determined by the adaptive difficulty engine.
enum AdaptationAction {
  /// Performance exceeded criteria; increase difficulty by one level.
  promote,

  /// Performance was below threshold or struggled repeatedly; decrease difficulty by one level.
  demote,

  /// Performance is within balanced expected range; retain current difficulty.
  maintain,

  /// Insufficient eligible gameplay history to make a performance-based adjustment.
  insufficientData,
}
