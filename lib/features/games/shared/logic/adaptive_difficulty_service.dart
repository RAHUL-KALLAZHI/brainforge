import 'package:flutter/foundation.dart';
import '../data/adaptive_difficulty_repository.dart';
import '../data/game_attempt_repository.dart';
import '../domain/adaptation_action.dart';
import '../domain/adaptation_decision.dart';
import '../domain/game_difficulty.dart';
import '../domain/player_game_profile.dart';
import 'adaptive_difficulty_policy.dart';

/// Application service coordinating history retrieval, policy evaluation, and profile persistence.
class AdaptiveDifficultyService {
  final GameAttemptRepository _attemptRepository;
  final AdaptiveDifficultyRepository _difficultyRepository;
  final AdaptiveDifficultyPolicy _policy;

  const AdaptiveDifficultyService({
    required GameAttemptRepository attemptRepository,
    required AdaptiveDifficultyRepository difficultyRepository,
    AdaptiveDifficultyPolicy policy = const AdaptiveDifficultyPolicy(),
  })  : _attemptRepository = attemptRepository,
        _difficultyRepository = difficultyRepository,
        _policy = policy;

  /// Retrieves the current effective starting difficulty for [gameId].
  Future<GameDifficulty> getEffectiveDifficulty(String gameId) async {
    return _difficultyRepository.getDifficulty(gameId);
  }

  /// Evaluates recent gameplay attempts and updates the persistent profile if a level change occurs.
  ///
  /// Only persists to the database when the difficulty level effectively changes,
  /// avoiding unnecessary database writes.
  Future<AdaptationDecision> evaluateAndPersist({
    required String gameId,
    required GameDifficulty currentDifficulty,
  }) async {
    // Retrieve recent attempts buffer (fetch up to 20 to ensure sufficient eligible attempts at current level)
    final recentAttempts = await _attemptRepository.getRecentAttempts(
      gameId: gameId,
      count: 20,
    );

    debugPrint(
      '[AdaptiveDifficultyService] Evaluation: gameId=$gameId, '
      'currentDifficulty=L${currentDifficulty.level}, '
      'fetchedAttemptsCount=${recentAttempts.length}, '
      'history=[${recentAttempts.map((a) => "L${a.difficultyLevel}:${a.status.name}:${(a.accuracy * 100).round()}%").join(", ")}]',
    );

    // Pure deterministic policy evaluation
    final decision = _policy.evaluate(
      currentDifficulty: currentDifficulty,
      recentAttempts: recentAttempts,
    );

    // Persist only when effective difficulty changes (promote or demote)
    if (decision.hasDifficultyChanged &&
        (decision.action == AdaptationAction.promote ||
            decision.action == AdaptationAction.demote)) {
      final updatedProfile = PlayerGameProfile(
        gameId: gameId,
        currentDifficulty: decision.targetDifficulty,
        lastAction: decision.action,
        lastReason: decision.reason,
        updatedAt: DateTime.now(),
      );

      await _difficultyRepository.saveProfile(updatedProfile);
      debugPrint(
        '[AdaptiveDifficultyService] Persisted new profile: gameId=$gameId, '
        'level=L${decision.targetDifficulty.level}, '
        'action=${decision.action.name}',
      );
    }

    return decision;
  }
}
