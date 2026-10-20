import 'package:flutter_test/flutter_test.dart';
import 'package:brainforge/features/games/shared/data/adaptive_difficulty_repository.dart';
import 'package:brainforge/features/games/shared/data/game_attempt_repository.dart';
import 'package:brainforge/features/games/shared/domain/adaptation_action.dart';
import 'package:brainforge/features/games/shared/domain/game_attempt.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';
import 'package:brainforge/features/games/shared/domain/player_game_profile.dart';
import 'package:brainforge/features/games/shared/logic/adaptive_difficulty_service.dart';

void main() {
  late InMemoryGameAttemptRepository attemptRepo;
  late InMemoryAdaptiveDifficultyRepository difficultyRepo;
  late AdaptiveDifficultyService service;

  setUp(() {
    attemptRepo = InMemoryGameAttemptRepository();
    difficultyRepo = InMemoryAdaptiveDifficultyRepository();
    service = AdaptiveDifficultyService(
      attemptRepository: attemptRepo,
      difficultyRepository: difficultyRepo,
    );
  });

  GameAttempt createAttempt({
    required String id,
    required double accuracy,
    GameStatus status = GameStatus.completed,
    int difficultyLevel = 2,
    int minutesAgo = 0,
  }) {
    final now = DateTime.now();
    return GameAttempt(
      id: id,
      gameId: 'memory_grid',
      difficultyLevel: difficultyLevel,
      status: status,
      finalScore: (accuracy * 1000).round(),
      accuracy: accuracy,
      correctCount: (accuracy * 5).round(),
      incorrectCount: ((1.0 - accuracy) * 5).round(),
      missedCount: 0,
      responseTimesMs: const [400, 450],
      startedAt: now.subtract(Duration(minutes: minutesAgo + 1)),
      completedAt: now.subtract(Duration(minutes: minutesAgo)),
    );
  }

  group('AdaptiveDifficultyService Unit Tests', () {
    test('getEffectiveDifficulty returns baseline (1) when no profile exists',
        () async {
      final difficulty = await service.getEffectiveDifficulty('memory_grid');
      expect(difficulty, equals(GameDifficulty.baseline));
    });

    test('getEffectiveDifficulty returns persisted level when profile exists',
        () async {
      await difficultyRepo.saveProfile(PlayerGameProfile(
        gameId: 'memory_grid',
        currentDifficulty: const GameDifficulty(4),
        updatedAt: DateTime.now(),
      ));

      final difficulty = await service.getEffectiveDifficulty('memory_grid');
      expect(difficulty, equals(const GameDifficulty(4)));
    });

    test('evaluateAndPersist promotes and updates repository on high accuracy',
        () async {
      await attemptRepo
          .saveAttempt(createAttempt(id: '1', accuracy: 1.0, minutesAgo: 3));
      await attemptRepo
          .saveAttempt(createAttempt(id: '2', accuracy: 1.0, minutesAgo: 2));
      await attemptRepo
          .saveAttempt(createAttempt(id: '3', accuracy: 0.95, minutesAgo: 1));

      final decision = await service.evaluateAndPersist(
        gameId: 'memory_grid',
        currentDifficulty: const GameDifficulty(2),
      );

      expect(decision.action, AdaptationAction.promote);
      expect(decision.targetDifficulty, const GameDifficulty(3));

      // Verify repository updated
      final updatedDifficulty =
          await difficultyRepo.getDifficulty('memory_grid');
      expect(updatedDifficulty, const GameDifficulty(3));
      final profile = await difficultyRepo.getProfile('memory_grid');
      expect(profile!.lastAction, AdaptationAction.promote);
    });

    test(
        'evaluateAndPersist demotes and updates repository on consecutive failures',
        () async {
      await attemptRepo.saveAttempt(createAttempt(
        id: '1',
        accuracy: 0.4,
        status: GameStatus.failed,
        difficultyLevel: 4,
        minutesAgo: 3,
      ));
      await attemptRepo.saveAttempt(createAttempt(
        id: '2',
        accuracy: 0.3,
        status: GameStatus.failed,
        difficultyLevel: 4,
        minutesAgo: 2,
      ));
      await attemptRepo.saveAttempt(createAttempt(
        id: '3',
        accuracy: 0.2,
        status: GameStatus.failed,
        difficultyLevel: 4,
        minutesAgo: 1,
      ));

      final decision = await service.evaluateAndPersist(
        gameId: 'memory_grid',
        currentDifficulty: const GameDifficulty(4),
      );

      expect(decision.action, AdaptationAction.demote);
      expect(decision.targetDifficulty, const GameDifficulty(3));

      final updatedDifficulty =
          await difficultyRepo.getDifficulty('memory_grid');
      expect(updatedDifficulty, const GameDifficulty(3));
    });

    test('evaluateAndPersist avoids writing when difficulty is maintained',
        () async {
      // 3 attempts with 75% accuracy (between 60% and 90%)
      await attemptRepo.saveAttempt(createAttempt(
          id: '1', accuracy: 0.75, difficultyLevel: 3, minutesAgo: 3));
      await attemptRepo.saveAttempt(createAttempt(
          id: '2', accuracy: 0.75, difficultyLevel: 3, minutesAgo: 2));
      await attemptRepo.saveAttempt(createAttempt(
          id: '3', accuracy: 0.75, difficultyLevel: 3, minutesAgo: 1));

      final decision = await service.evaluateAndPersist(
        gameId: 'memory_grid',
        currentDifficulty: const GameDifficulty(3),
      );

      expect(decision.action, AdaptationAction.maintain);
      expect(decision.targetDifficulty, const GameDifficulty(3));

      // Verify repository was NOT written to
      final profile = await difficultyRepo.getProfile('memory_grid');
      expect(profile, isNull);
    });

    test(
        'evaluateAndPersist handles insufficient history safely without writes',
        () async {
      await attemptRepo
          .saveAttempt(createAttempt(id: '1', accuracy: 1.0, minutesAgo: 1));

      final decision = await service.evaluateAndPersist(
        gameId: 'memory_grid',
        currentDifficulty: const GameDifficulty(2),
      );

      expect(decision.action, AdaptationAction.insufficientData);
      expect(decision.targetDifficulty, const GameDifficulty(2));

      final profile = await difficultyRepo.getProfile('memory_grid');
      expect(profile, isNull);
    });
  });
}
