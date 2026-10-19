import 'dart:async';
import 'package:flutter/foundation.dart';
import 'ticker.dart';

/// Service managing countdowns, round response limits, and elapsed session duration.
class GameTimer {
  final Ticker _ticker;
  final Stopwatch _elapsedStopwatch;

  StreamSubscription<int>? _countdownSubscription;
  StreamSubscription<int>? _responseSubscription;

  Duration _remainingResponseTime = Duration.zero;

  void Function(Duration remaining)? _onResponseTick;
  VoidCallback? _onResponseTimeout;

  GameTimer({Ticker ticker = const RealTicker()})
      : _ticker = ticker,
        _elapsedStopwatch = Stopwatch();

  /// Elapsed active gameplay duration (excludes pauses).
  Duration get elapsedActiveTime => _elapsedStopwatch.elapsed;

  /// Remaining response time for the active round.
  Duration get remainingResponseTime => _remainingResponseTime;

  /// Starts the elapsed active stopwatch.
  void startSessionTimer() {
    _elapsedStopwatch.reset();
    _elapsedStopwatch.start();
  }

  /// Initiates pre-game countdown (e.g. 3, 2, 1) emitting [onTick] per second and calling [onComplete].
  void startCountdown({
    required int seconds,
    required void Function(int remainingSeconds) onTick,
    required VoidCallback onComplete,
    Duration interval = const Duration(seconds: 1),
  }) {
    _countdownSubscription?.cancel();
    _countdownSubscription =
        _ticker.countdown(ticks: seconds, interval: interval).listen(
              (remaining) => onTick(remaining),
              onDone: onComplete,
              cancelOnError: true,
            );
  }

  /// Initiates response countdown window for the current round.
  void startResponseWindow({
    required Duration timeLimit,
    required void Function(Duration remaining) onTick,
    required VoidCallback onTimeout,
    Duration interval = const Duration(milliseconds: 100),
  }) {
    _responseSubscription?.cancel();
    _remainingResponseTime = timeLimit;
    _onResponseTick = onTick;
    _onResponseTimeout = onTimeout;

    final totalTicks =
        (timeLimit.inMilliseconds / interval.inMilliseconds).ceil();
    if (totalTicks <= 0) {
      onTimeout();
      return;
    }

    _responseSubscription =
        _ticker.countdown(ticks: totalTicks, interval: interval).listen(
      (remainingTicks) {
        final remainingMs = remainingTicks * interval.inMilliseconds;
        _remainingResponseTime = Duration(milliseconds: remainingMs);
        _onResponseTick?.call(_remainingResponseTime);
      },
      onDone: () {
        _remainingResponseTime = Duration.zero;
        _onResponseTimeout?.call();
      },
      cancelOnError: true,
    );
  }

  /// Cancels any active round response window (e.g. when player submits input).
  void stopResponseWindow() {
    _responseSubscription?.cancel();
    _responseSubscription = null;
  }

  /// Pauses elapsed stopwatch and suspends response window countdown.
  void pause() {
    if (_elapsedStopwatch.isRunning) {
      _elapsedStopwatch.stop();
    }
    _countdownSubscription?.pause();
    _responseSubscription?.pause();
  }

  /// Resumes elapsed stopwatch and resumes response window countdown.
  void resume() {
    if (!_elapsedStopwatch.isRunning) {
      _elapsedStopwatch.start();
    }
    if (_countdownSubscription?.isPaused == true) {
      _countdownSubscription?.resume();
    }
    if (_responseSubscription?.isPaused == true) {
      _responseSubscription?.resume();
    }
  }

  /// Stops all timers and cancels active subscriptions.
  void stop() {
    _elapsedStopwatch.stop();
    _countdownSubscription?.cancel();
    _responseSubscription?.cancel();
    _countdownSubscription = null;
    _responseSubscription = null;
  }

  /// Disposes resources.
  void dispose() {
    stop();
  }
}
