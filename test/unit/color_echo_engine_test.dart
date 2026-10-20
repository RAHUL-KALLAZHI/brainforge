import 'package:flutter_test/flutter_test.dart';
import 'package:brainforge/features/games/color_echo/domain/color_echo_config.dart';
import 'package:brainforge/features/games/color_echo/logic/color_echo_engine.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';
import 'package:brainforge/features/games/shared/logic/challenge_generator.dart';
import 'package:brainforge/features/games/shared/logic/game_timer.dart';
import 'package:brainforge/features/games/shared/logic/ticker.dart';

void main() {
  group('ColorEchoConfig & Difficulty Mapping Tests', () {
    test('Game ID and Title constants are correct', () {
      expect(ColorEchoConfig.gameId, 'color_echo');
      expect(ColorEchoConfig.gameTitle, 'Color Echo');
      expect(ColorEchoConfig.pads.length, 4);
    });

    test('The 4 color pads have distinct names, indices, and accessible labels',
        () {
      final names = ColorEchoConfig.pads.map((p) => p.name).toSet();
      final indices = ColorEchoConfig.pads.map((p) => p.index).toSet();
      final labels = ColorEchoConfig.pads.map((p) => p.semanticLabel).toSet();

      expect(names, containsAll(['Cyan', 'Violet', 'Amber', 'Green']));
      expect(indices, equals({0, 1, 2, 3}));
      expect(labels.length, 4);
    });

    test('Levels 1 to 10 scale sequence length from 3 to 12 deterministically',
        () {
      final expectedLengths = {
        1: 3,
        2: 4,
        3: 5,
        4: 6,
        5: 7,
        6: 8,
        7: 9,
        8: 10,
        9: 11,
        10: 12,
      };

      for (var level = 1; level <= 10; level++) {
        final config =
            ColorEchoConfig.forDifficulty(GameDifficulty(level), seed: 100);
        expect(config.sequenceLength, expectedLengths[level],
            reason: 'Failed sequence length for Level $level');
        expect(config.gridRows, 2);
        expect(config.gridColumns, 2);
        expect(config.allowDuplicates, isTrue);
        expect(config.responseTimeLimit, const Duration(seconds: 15));
      }
    });

    test('Presentation durations scale from 800ms down to 350ms', () {
      final level1 =
          ColorEchoConfig.forDifficulty(const GameDifficulty(1), seed: 10);
      final level5 =
          ColorEchoConfig.forDifficulty(const GameDifficulty(5), seed: 10);
      final level10 =
          ColorEchoConfig.forDifficulty(const GameDifficulty(10), seed: 10);

      expect(level1.presentationDuration, const Duration(milliseconds: 800));
      expect(level5.presentationDuration, const Duration(milliseconds: 600));
      expect(level10.presentationDuration, const Duration(milliseconds: 350));
    });

    test('Gap durations scale from 200ms down to 100ms', () {
      expect(
        ColorEchoConfig.gapDurationForDifficulty(const GameDifficulty(1)),
        const Duration(milliseconds: 200),
      );
      expect(
        ColorEchoConfig.gapDurationForDifficulty(const GameDifficulty(6)),
        const Duration(milliseconds: 150),
      );
      expect(
        ColorEchoConfig.gapDurationForDifficulty(const GameDifficulty(10)),
        const Duration(milliseconds: 100),
      );
    });
  });

  group('ColorEchoEngine Pure-Dart Logic Tests', () {
    const engine = ColorEchoEngine();

    test('Deterministic challenge generation with identical seeds', () {
      final configA =
          ColorEchoConfig.forDifficulty(const GameDifficulty(3), seed: 42);
      final configB =
          ColorEchoConfig.forDifficulty(const GameDifficulty(3), seed: 42);

      final challengeA = engine.generateEchoChallenge(config: configA);
      final challengeB = engine.generateEchoChallenge(config: configB);

      expect(challengeA.sequence, equals(challengeB.sequence));
      expect(challengeA.sequence.length, 5);
      expect(challengeA.totalPoolSize, 4);
    });

    test('Different seeds produce different sequences', () {
      final configA =
          ColorEchoConfig.forDifficulty(const GameDifficulty(4), seed: 12345);
      final configB =
          ColorEchoConfig.forDifficulty(const GameDifficulty(4), seed: 67890);

      final challengeA = engine.generateEchoChallenge(config: configA);
      final challengeB = engine.generateEchoChallenge(config: configB);

      expect(challengeA.sequence, isNot(equals(challengeB.sequence)));
    });

    test('Generated sequences only contain valid pad indices (0, 1, 2, 3)', () {
      for (var seed = 1; seed <= 20; seed++) {
        final config =
            ColorEchoConfig.forDifficulty(const GameDifficulty(5), seed: seed);
        final challenge = engine.generateEchoChallenge(config: config);

        for (final pad in challenge.sequence) {
          expect(pad, inInclusiveRange(0, 3));
        }
      }
    });

    test('Repeated items are permitted in Color Echo sequences', () {
      // With allowDuplicates = true across multiple seeds, repeated pads occur naturally
      var foundRepeat = false;
      for (var seed = 1; seed <= 50; seed++) {
        final config =
            ColorEchoConfig.forDifficulty(const GameDifficulty(6), seed: seed);
        final challenge = engine.generateEchoChallenge(config: config);
        final uniqueItems = challenge.sequence.toSet();
        if (uniqueItems.length < challenge.sequence.length) {
          foundRepeat = true;
          break;
        }
      }
      expect(foundRepeat, isTrue,
          reason: 'Expected duplicates in Color Echo sequences');
    });

    test('evaluateInput correctly checks matching and non-matching pad indices',
        () {
      const challenge = SequenceChallenge(
        roundIndex: 0,
        sequence: [0, 2, 1, 3],
        totalPoolSize: 4,
      );

      // Step 0: expects 0
      expect(engine.evaluateInput(challenge: challenge, input: 0, stepIndex: 0),
          isTrue);
      expect(engine.evaluateInput(challenge: challenge, input: 1, stepIndex: 0),
          isFalse);
      expect(engine.evaluateInput(challenge: challenge, input: 2, stepIndex: 0),
          isFalse);

      // Step 1: expects 2
      expect(engine.evaluateInput(challenge: challenge, input: 2, stepIndex: 1),
          isTrue);
      expect(engine.evaluateInput(challenge: challenge, input: 0, stepIndex: 1),
          isFalse);

      // Step 2: expects 1
      expect(engine.evaluateInput(challenge: challenge, input: 1, stepIndex: 2),
          isTrue);

      // Step 3: expects 3
      expect(engine.evaluateInput(challenge: challenge, input: 3, stepIndex: 3),
          isTrue);

      // Out of bounds step index
      expect(
          engine.evaluateInput(challenge: challenge, input: 0, stepIndex: -1),
          isFalse);
      expect(engine.evaluateInput(challenge: challenge, input: 0, stepIndex: 4),
          isFalse);
    });

    test('Session lifecycle through GameStateMachine with ColorEchoEngine', () {
      final config =
          ColorEchoConfig.forDifficulty(const GameDifficulty(1), seed: 99);
      final testTicker = ControllableTestTicker();
      final timer = GameTimer(ticker: testTicker);
      final session = engine.createSession(config: config, timer: timer);

      expect(session.state.status, GameStatus.initial);

      // Countdown
      session.startCountdown(seconds: 1);
      expect(session.state.status, GameStatus.countdown);

      // Transition to playing preview
      session.startPlaying();
      expect(session.state.status, GameStatus.playing);

      // Input phase
      session.setPhase(GamePhase.input);
      expect(session.state.phase, GamePhase.input);

      // Input recording
      final inputAccepted = session.recordInput(
        isCorrect: true,
        responseLatency: const Duration(milliseconds: 400),
      );
      expect(inputAccepted, isTrue);

      // Complete session
      session.completeSession();
      expect(session.state.status, GameStatus.completed);
      expect(session.state.result, isNotNull);
      expect(session.state.result!.score.scaledScore, greaterThan(0));

      session.dispose();
    });
  });
}
