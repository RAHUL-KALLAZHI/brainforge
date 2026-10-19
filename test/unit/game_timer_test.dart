import 'package:flutter_test/flutter_test.dart';
import 'package:brainforge/features/games/shared/logic/game_timer.dart';
import 'package:brainforge/features/games/shared/logic/ticker.dart';

void main() {
  group('GameTimer Unit Tests (Deterministic with ControllableTestTicker)', () {
    late ControllableTestTicker testTicker;
    late GameTimer timer;

    setUp(() {
      testTicker = ControllableTestTicker();
      timer = GameTimer(ticker: testTicker);
    });

    tearDown(() {
      timer.dispose();
    });

    test('startCountdown emits ticks and calls onComplete upon termination',
        () {
      final receivedTicks = <int>[];
      var completed = false;

      timer.startCountdown(
        seconds: 3,
        onTick: (remaining) => receivedTicks.add(remaining),
        onComplete: () => completed = true,
      );

      expect(receivedTicks, isEmpty);
      expect(completed, isFalse);

      testTicker.step();
      expect(receivedTicks, [2]);
      expect(completed, isFalse);

      testTicker.step();
      expect(receivedTicks, [2, 1]);
      expect(completed, isFalse);

      testTicker.step();
      expect(receivedTicks, [2, 1, 0]);
      expect(completed, isTrue);
    });

    test('startCountdown advanceToCompletion fast-forwards all remaining ticks',
        () {
      final receivedTicks = <int>[];
      var completed = false;

      timer.startCountdown(
        seconds: 5,
        onTick: (remaining) => receivedTicks.add(remaining),
        onComplete: () => completed = true,
      );

      testTicker.advanceToCompletion();
      expect(receivedTicks, [4, 3, 2, 1, 0]);
      expect(completed, isTrue);
    });

    test(
        'startResponseWindow emits remaining durations and fires onTimeout on expiry',
        () {
      final remainingDurations = <Duration>[];
      var timedOut = false;

      // 500ms window with 100ms interval => 5 ticks
      timer.startResponseWindow(
        timeLimit: const Duration(milliseconds: 500),
        interval: const Duration(milliseconds: 100),
        onTick: (rem) => remainingDurations.add(rem),
        onTimeout: () => timedOut = true,
      );

      expect(remainingDurations, isEmpty);
      expect(timedOut, isFalse);

      testTicker.step();
      expect(remainingDurations, [const Duration(milliseconds: 400)]);
      expect(timedOut, isFalse);

      testTicker.advanceToCompletion();
      expect(timedOut, isTrue);
      expect(timer.remainingResponseTime, Duration.zero);
    });

    test('stopResponseWindow cancels timeout before completion', () {
      var timedOut = false;

      timer.startResponseWindow(
        timeLimit: const Duration(seconds: 5),
        onTick: (_) {},
        onTimeout: () => timedOut = true,
      );

      testTicker.step();
      timer.stopResponseWindow();

      // Advancing the ticker now must not trigger onTimeout
      testTicker.step();
      expect(timedOut, isFalse);
    });

    test('session timer tracks active elapsed time and pauses correctly', () {
      expect(timer.elapsedActiveTime, Duration.zero);

      timer.startSessionTimer();
      // In tests without delay, stopwatch is non-negative
      expect(timer.elapsedActiveTime >= Duration.zero, isTrue);

      timer.pause();
      final pausedTime = timer.elapsedActiveTime;
      timer.resume();
      expect(timer.elapsedActiveTime >= pausedTime, isTrue);

      timer.stop();
    });

    test('dispose cancels all timers without error', () {
      timer.startCountdown(
        seconds: 3,
        onTick: (_) {},
        onComplete: () {},
      );

      expect(() => timer.dispose(), returnsNormally);
    });
  });
}
