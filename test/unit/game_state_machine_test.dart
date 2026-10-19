import 'package:flutter_test/flutter_test.dart';
import 'package:brainforge/features/games/shared/domain/game_config.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';
import 'package:brainforge/features/games/shared/logic/game_state_machine.dart';
import 'package:brainforge/features/games/shared/logic/game_timer.dart';
import 'package:brainforge/features/games/shared/logic/ticker.dart';

void main() {
  group('GameStateMachine Unit Tests', () {
    late ControllableTestTicker testTicker;
    late GameTimer testTimer;
    late GameConfig config;
    late GameStateMachine machine;

    setUp(() {
      testTicker = ControllableTestTicker();
      testTimer = GameTimer(ticker: testTicker);
      config = const GameConfig(
        gameId: 'memory_grid',
        difficulty: GameDifficulty(2),
        gridRows: 3,
        gridColumns: 3,
        sequenceLength: 4,
        targetRounds: 3,
        seed: 123,
      );
      machine = GameStateMachine(
        config: config,
        timer: testTimer,
      );
    });

    tearDown(() {
      machine.dispose();
    });

    test('initial state is configured properly', () {
      expect(machine.state.status, GameStatus.initial);
      expect(machine.state.phase, GamePhase.preview);
      expect(machine.state.currentRound, 1);
      expect(machine.state.correctCount, 0);
      expect(machine.state.incorrectCount, 0);
      expect(machine.state.isInputAllowed, isFalse);
    });

    test(
        'valid lifecycle transition: initial -> instructions -> countdown -> playing -> completed',
        () {
      var notifications = 0;
      machine.addListener(() => notifications++);

      // 1. Initial -> Instructions
      machine.showInstructions();
      expect(machine.state.status, GameStatus.instructions);

      // 2. Instructions -> Countdown
      machine.startCountdown(seconds: 3);
      expect(machine.state.status, GameStatus.countdown);
      expect(machine.state.countdownSecondsRemaining, 3);

      // Advance countdown ticks
      testTicker.advanceToCompletion();
      expect(machine.state.status, GameStatus.playing);
      expect(machine.state.startedAt, isNotNull);

      // 3. Playing -> Completed
      machine.completeSession();
      expect(machine.state.status, GameStatus.completed);
      expect(machine.state.status.isTerminal, isTrue);
      expect(machine.state.result, isNotNull);
      expect(notifications, greaterThan(3));
    });

    test('invalid state transitions throw InvalidStateTransitionException', () {
      // Cannot jump directly from initial to playing without countdown
      expect(
        () => machine.startPlaying(),
        throwsA(isA<InvalidStateTransitionException>()),
      );

      // Cannot jump from initial to paused
      expect(
        () => machine.pause(),
        returnsNormally, // pause() guards with if (_state.status != GameStatus.playing) return;
      );
      expect(machine.state.status, GameStatus.initial);

      // Transition to instructions
      machine.showInstructions();

      // Cannot jump from instructions to playing
      expect(
        () => machine.startPlaying(),
        throwsA(isA<InvalidStateTransitionException>()),
      );
    });

    test('pause and resume lifecycle works during active gameplay', () {
      machine.startCountdown(seconds: 1);
      testTicker.advanceToCompletion();
      expect(machine.state.status, GameStatus.playing);

      machine.pause();
      expect(machine.state.status, GameStatus.paused);
      expect(machine.state.isInputAllowed, isFalse);

      machine.resume();
      expect(machine.state.status, GameStatus.playing);
    });

    test(
        'input is gated and disallowed outside input phase or during pause/countdown',
        () {
      // Initial state
      var accepted = machine.recordInput(
        isCorrect: true,
        responseLatency: const Duration(milliseconds: 500),
      );
      expect(accepted, isFalse);

      // Countdown state
      machine.startCountdown(seconds: 3);
      accepted = machine.recordInput(
        isCorrect: true,
        responseLatency: const Duration(milliseconds: 500),
      );
      expect(accepted, isFalse);

      // Playing, but still in preview phase
      testTicker.advanceToCompletion();
      expect(machine.state.status, GameStatus.playing);
      expect(machine.state.phase, GamePhase.preview);
      accepted = machine.recordInput(
        isCorrect: true,
        responseLatency: const Duration(milliseconds: 500),
      );
      expect(accepted, isFalse);

      // Transition to input phase
      machine.setPhase(GamePhase.input);
      expect(machine.state.isInputAllowed, isTrue);
      accepted = machine.recordInput(
        isCorrect: true,
        responseLatency: const Duration(milliseconds: 500),
      );
      expect(accepted, isTrue);
      expect(machine.state.correctCount, 1);
      expect(machine.state.responseTimesMs, [500]);
    });

    test('late input is rejected after timeout fails the session', () {
      machine.startCountdown(seconds: 1);
      testTicker.advanceToCompletion();
      machine.setPhase(GamePhase.input);

      // Start response window of 1 second (10 ticks of 100ms)
      machine.startRoundResponseTimer(timeLimit: const Duration(seconds: 1));

      // Advance ticker until timeout expires
      testTicker.advanceToCompletion();

      // Session should now be failed due to timeout
      expect(machine.state.status, GameStatus.failed);
      expect(machine.state.isInputAllowed, isFalse);

      // Player attempts late response after timeout
      final accepted = machine.recordInput(
        isCorrect: true,
        responseLatency: const Duration(seconds: 2),
      );
      expect(accepted, isFalse);
      expect(machine.state.correctCount, 0);
    });

    test(
        'recording valid input stops response window and prevents timeout race conditions',
        () {
      machine.startCountdown(seconds: 1);
      testTicker.advanceToCompletion();
      machine.setPhase(GamePhase.input);

      machine.startRoundResponseTimer(timeLimit: const Duration(seconds: 1));

      // User responds before timeout
      testTicker.step(); // one tick
      final accepted = machine.recordInput(
        isCorrect: true,
        responseLatency: const Duration(milliseconds: 200),
      );
      expect(accepted, isTrue);

      // Now advance ticker completely
      testTicker.advanceToCompletion();

      // Status must NOT be failed because response window was stopped
      expect(machine.state.status, GameStatus.playing);
    });

    test(
        'duplicate completion calls are idempotent and prevent duplicate events',
        () {
      machine.startCountdown(seconds: 1);
      testTicker.advanceToCompletion();
      machine.setPhase(GamePhase.input);
      machine.recordInput(
        isCorrect: true,
        responseLatency: const Duration(milliseconds: 300),
      );

      machine.completeSession();
      final firstResult = machine.state.result;
      expect(machine.state.status, GameStatus.completed);

      // Attempt second complete
      machine.completeSession();
      expect(machine.state.result, equals(firstResult));

      // Attempt fail on completed session
      machine.failSession();
      expect(machine.state.status, GameStatus.completed);
    });

    test('abandonSession terminates session immediately and awards zero score',
        () {
      machine.startCountdown(seconds: 1);
      testTicker.advanceToCompletion();
      machine.setPhase(GamePhase.input);

      machine.abandonSession();
      expect(machine.state.status, GameStatus.abandoned);
      expect(machine.state.result!.score.scaledScore, 0);
      expect(machine.state.result!.score.isAbandoned, isTrue);

      // Disallow further input
      final accepted = machine.recordInput(
        isCorrect: true,
        responseLatency: const Duration(milliseconds: 100),
      );
      expect(accepted, isFalse);
    });

    test('restart resets state to initial with either same or new config', () {
      machine.startCountdown(seconds: 1);
      testTicker.advanceToCompletion();
      machine.completeSession();

      // Restart with original config
      machine.restart();
      expect(machine.state.status, GameStatus.initial);
      expect(machine.state.correctCount, 0);
      expect(machine.state.result, isNull);

      // Can now start countdown again
      machine.startCountdown(seconds: 2);
      expect(machine.state.status, GameStatus.countdown);
    });
  });
}
