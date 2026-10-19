import 'dart:async';

/// Abstract ticker service contract to decouple timers from real-world wall clocks.
///
/// Permits 100% deterministic unit tests using [ControllableTestTicker] without
/// sleeping or relying on non-deterministic real-time delays.
abstract class Ticker {
  /// Emits countdown integers from [ticks] down to 1 at [interval] intervals.
  Stream<int> countdown({
    required int ticks,
    required Duration interval,
  });
}

/// Standard production ticker using [Stream.periodic].
class RealTicker implements Ticker {
  const RealTicker();

  @override
  Stream<int> countdown({
    required int ticks,
    required Duration interval,
  }) {
    return Stream.periodic(
      interval,
      (step) => ticks - step - 1,
    ).take(ticks);
  }
}

/// Controllable test ticker that allows unit tests to step forward deterministically.
class ControllableTestTicker implements Ticker {
  StreamController<int>? _currentController;
  int _remainingTicks = 0;

  @override
  Stream<int> countdown({
    required int ticks,
    required Duration interval,
  }) {
    _remainingTicks = ticks;
    _currentController = StreamController<int>(sync: true);
    return _currentController!.stream;
  }

  /// Manually advance one countdown tick.
  void step() {
    if (_currentController == null || _currentController!.isClosed) return;
    if (_remainingTicks > 0) {
      _remainingTicks--;
      _currentController!.add(_remainingTicks);
      if (_remainingTicks == 0) {
        _currentController!.close();
      }
    }
  }

  /// Fast-forwards all remaining ticks to simulate immediate countdown completion.
  void advanceToCompletion() {
    while (_remainingTicks > 0 &&
        _currentController != null &&
        !_currentController!.isClosed) {
      step();
    }
  }

  /// Cancels any active test countdown stream.
  void cancel() {
    _currentController?.close();
  }
}
