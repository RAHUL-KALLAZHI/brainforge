import 'package:flutter_test/flutter_test.dart';
import 'package:brainforge/features/games/shared/domain/game_config.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';

void main() {
  group('GameConfig Unit Tests', () {
    test('valid configuration succeeds validation', () {
      const config = GameConfig(
        gameId: 'memory_grid',
        difficulty: GameDifficulty(3),
        gridRows: 3,
        gridColumns: 3,
        sequenceLength: 4,
        presentationDuration: Duration(milliseconds: 800),
        responseTimeLimit: Duration(seconds: 10),
        distractorCount: 1,
        targetRounds: 5,
        seed: 42,
      );

      expect(() => config.validate(), returnsNormally);
      expect(config.gameId, 'memory_grid');
      expect(config.difficulty.level, 3);
      expect(config.gridRows, 3);
      expect(config.gridColumns, 3);
      expect(config.sequenceLength, 4);
      expect(config.seed, 42);
    });

    test('empty or whitespace gameId throws GameConfigException', () {
      const config = GameConfig(
        gameId: '   ',
        difficulty: GameDifficulty(1),
      );
      expect(() => config.validate(), throwsA(isA<GameConfigException>()));
    });

    test('invalid grid dimensions throw GameConfigException', () {
      const invalidRows = GameConfig(
        gameId: 'test_game',
        difficulty: GameDifficulty(1),
        gridRows: 1,
        gridColumns: 3,
      );
      expect(() => invalidRows.validate(), throwsA(isA<GameConfigException>()));

      const invalidCols = GameConfig(
        gameId: 'test_game',
        difficulty: GameDifficulty(1),
        gridRows: 3,
        gridColumns: 1,
      );
      expect(() => invalidCols.validate(), throwsA(isA<GameConfigException>()));
    });

    test('sequenceLength exceeding total tiles throws GameConfigException', () {
      const config = GameConfig(
        gameId: 'test_game',
        difficulty: GameDifficulty(1),
        gridRows: 2,
        gridColumns: 2,
        sequenceLength: 5, // total tiles is 4
      );
      expect(() => config.validate(), throwsA(isA<GameConfigException>()));
    });

    test('sequenceLength less than 1 throws GameConfigException', () {
      const config = GameConfig(
        gameId: 'test_game',
        difficulty: GameDifficulty(1),
        sequenceLength: 0,
      );
      expect(() => config.validate(), throwsA(isA<GameConfigException>()));
    });

    test('non-positive presentationDuration throws GameConfigException', () {
      const zeroDuration = GameConfig(
        gameId: 'test_game',
        difficulty: GameDifficulty(1),
        presentationDuration: Duration.zero,
      );
      expect(
          () => zeroDuration.validate(), throwsA(isA<GameConfigException>()));

      const negativeDuration = GameConfig(
        gameId: 'test_game',
        difficulty: GameDifficulty(1),
        presentationDuration: Duration(milliseconds: -100),
      );
      expect(() => negativeDuration.validate(),
          throwsA(isA<GameConfigException>()));
    });

    test('non-positive responseTimeLimit throws GameConfigException', () {
      const zeroLimit = GameConfig(
        gameId: 'test_game',
        difficulty: GameDifficulty(1),
        responseTimeLimit: Duration.zero,
      );
      expect(() => zeroLimit.validate(), throwsA(isA<GameConfigException>()));
    });

    test('negative distractorCount throws GameConfigException', () {
      const config = GameConfig(
        gameId: 'test_game',
        difficulty: GameDifficulty(1),
        distractorCount: -1,
      );
      expect(() => config.validate(), throwsA(isA<GameConfigException>()));
    });

    test('targetRounds less than 1 throws GameConfigException', () {
      const config = GameConfig(
        gameId: 'test_game',
        difficulty: GameDifficulty(1),
        targetRounds: 0,
      );
      expect(() => config.validate(), throwsA(isA<GameConfigException>()));
    });

    test('copyWith modifies only specified fields', () {
      const original = GameConfig(
        gameId: 'memory_grid',
        difficulty: GameDifficulty(2),
        gridRows: 3,
        gridColumns: 3,
      );

      final modified = original.copyWith(
        difficulty: const GameDifficulty(5),
        sequenceLength: 6,
      );

      expect(modified.gameId, 'memory_grid');
      expect(modified.difficulty.level, 5);
      expect(modified.gridRows, 3);
      expect(modified.sequenceLength, 6);
    });

    test('Equatable value equality', () {
      const a = GameConfig(
        gameId: 'color_echo',
        difficulty: GameDifficulty(4),
        seed: 99,
      );
      const b = GameConfig(
        gameId: 'color_echo',
        difficulty: GameDifficulty(4),
        seed: 99,
      );
      const c = GameConfig(
        gameId: 'color_echo',
        difficulty: GameDifficulty(5),
        seed: 99,
      );

      expect(a, equals(b));
      expect(a == c, isFalse);
    });
  });
}
