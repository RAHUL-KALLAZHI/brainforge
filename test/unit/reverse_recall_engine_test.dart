import 'package:flutter_test/flutter_test.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import 'package:brainforge/features/games/reverse_recall/domain/reverse_recall_config.dart';
import 'package:brainforge/features/games/reverse_recall/logic/reverse_recall_engine.dart';
import 'package:brainforge/features/games/reverse_recall/logic/reverse_recall_generator.dart';

void main() {
  group('ReverseRecallConfig & Difficulty Mapping Tests', () {
    test('Game ID and Title constants are correct', () {
      expect(ReverseRecallConfig.gameId, 'reverse_recall');
      expect(ReverseRecallConfig.gameTitle, 'Reverse Recall');
      expect(ReverseRecallConfig.standardPool, [1, 2, 3, 4, 5, 6, 7, 8, 9]);
    });

    test('Levels 1 to 10 scale sequence length deterministically from 3 to 12',
        () {
      for (var level = 1; level <= 10; level++) {
        final difficulty = GameDifficulty(level);
        final length =
            ReverseRecallConfig.sequenceLengthForDifficulty(difficulty);
        expect(length, equals(2 + level));

        final config = ReverseRecallConfig.forDifficulty(difficulty, seed: 123);
        expect(config.sequenceLength, equals(2 + level));
        expect(config.targetRounds, equals(1));
        expect(config.responseTimeLimit, equals(const Duration(seconds: 20)));
      }
    });

    test('Presentation durations scale down as difficulty increases', () {
      final l1Duration = ReverseRecallConfig.presentationDurationForDifficulty(
          const GameDifficulty(1));
      final l5Duration = ReverseRecallConfig.presentationDurationForDifficulty(
          const GameDifficulty(5));
      final l10Duration = ReverseRecallConfig.presentationDurationForDifficulty(
          const GameDifficulty(10));

      expect(l1Duration.inMilliseconds, greaterThan(l5Duration.inMilliseconds));
      expect(
          l5Duration.inMilliseconds, greaterThan(l10Duration.inMilliseconds));
      expect(l1Duration.inMilliseconds, equals(1000));
      expect(l10Duration.inMilliseconds, equals(550));
    });

    test('Gap durations scale down as difficulty increases', () {
      final l1Gap =
          ReverseRecallConfig.gapDurationForDifficulty(const GameDifficulty(1));
      final l5Gap =
          ReverseRecallConfig.gapDurationForDifficulty(const GameDifficulty(5));
      final l10Gap = ReverseRecallConfig.gapDurationForDifficulty(
          const GameDifficulty(10));

      expect(l1Gap.inMilliseconds, greaterThan(l5Gap.inMilliseconds));
      expect(l5Gap.inMilliseconds, greaterThan(l10Gap.inMilliseconds));
      expect(l1Gap.inMilliseconds, equals(300));
      expect(l10Gap.inMilliseconds, equals(120));
    });
  });

  group('ReverseRecallGenerator Tests', () {
    const generator = ReverseRecallGenerator();

    test('Same seed produces identical challenge', () {
      final config1 =
          ReverseRecallConfig.forDifficulty(const GameDifficulty(4), seed: 42);
      final config2 =
          ReverseRecallConfig.forDifficulty(const GameDifficulty(4), seed: 42);

      final challenge1 = generator.generate(roundIndex: 0, config: config1);
      final challenge2 = generator.generate(roundIndex: 0, config: config2);

      expect(challenge1.sequence, equals(challenge2.sequence));
      expect(challenge1.expectedReverse, equals(challenge2.expectedReverse));
    });

    test('Different seeds can produce different sequences', () {
      final config1 =
          ReverseRecallConfig.forDifficulty(const GameDifficulty(5), seed: 100);
      final config2 = ReverseRecallConfig.forDifficulty(const GameDifficulty(5),
          seed: 9999);

      final challenge1 = generator.generate(roundIndex: 0, config: config1);
      final challenge2 = generator.generate(roundIndex: 0, config: config2);

      expect(challenge1.sequence, isNot(equals(challenge2.sequence)));
    });

    test(
        'Generated sequence has exact expected length and no adjacent duplicates',
        () {
      for (var level = 1; level <= 10; level++) {
        final config = ReverseRecallConfig.forDifficulty(GameDifficulty(level),
            seed: 50 + level);
        final challenge = generator.generate(roundIndex: 0, config: config);

        expect(challenge.sequence.length, equals(2 + level));
        expect(challenge.expectedReverse.length, equals(2 + level));

        // Digits are all in pool
        for (final digit in challenge.sequence) {
          expect(challenge.pool.contains(digit), isTrue);
        }

        // No adjacent duplicates
        for (var i = 0; i < challenge.sequence.length - 1; i++) {
          expect(
              challenge.sequence[i], isNot(equals(challenge.sequence[i + 1])));
        }
      }
    });

    test('expectedReverse is exactly the reverse of sequence', () {
      final config =
          ReverseRecallConfig.forDifficulty(const GameDifficulty(3), seed: 777);
      final challenge = generator.generate(roundIndex: 0, config: config);

      expect(challenge.expectedReverse,
          equals(challenge.sequence.reversed.toList()));
    });
  });

  group('ReverseRecallEngine Pure Logic Tests', () {
    const engine = ReverseRecallEngine();

    test(
        'evaluateInput returns true for matching expected reverse digit at step index',
        () {
      final config = ReverseRecallConfig.forDifficulty(const GameDifficulty(1),
          seed: 1234);
      final challenge = engine.generateReverseChallenge(config: config);

      for (var i = 0; i < challenge.expectedReverse.length; i++) {
        final expectedDigit = challenge.expectedReverse[i];
        expect(
            engine.evaluateInput(
                challenge: challenge, input: expectedDigit, stepIndex: i),
            isTrue);
      }
    });

    test('evaluateInput returns false for mismatched digit', () {
      final config = ReverseRecallConfig.forDifficulty(const GameDifficulty(1),
          seed: 1234);
      final challenge = engine.generateReverseChallenge(config: config);

      final expectedDigit = challenge.expectedReverse.first;
      final wrongDigit = expectedDigit == 9 ? 1 : expectedDigit + 1;

      expect(
          engine.evaluateInput(
              challenge: challenge, input: wrongDigit, stepIndex: 0),
          isFalse);
    });

    test('evaluateInput returns false for out-of-bounds step indices', () {
      final config = ReverseRecallConfig.forDifficulty(const GameDifficulty(1),
          seed: 1234);
      final challenge = engine.generateReverseChallenge(config: config);

      expect(
          engine.evaluateInput(
              challenge: challenge,
              input: challenge.expectedReverse[0],
              stepIndex: -1),
          isFalse);
      expect(
          engine.evaluateInput(
              challenge: challenge,
              input: challenge.expectedReverse[0],
              stepIndex: 999),
          isFalse);
    });
  });
}
