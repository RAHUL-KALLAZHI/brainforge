# BrainForge — Testing Strategy & Verification Guide

This document describes the testing principles, deterministic timing abstractions, and automated test coverage for the BrainForge mobile application.

---

## 1. Testing Principles

1. **Zero Flakiness:** Unit tests avoid `Future.delayed` or arbitrary wall-clock sleeps. Timing behavior is verified using deterministic abstractions (`ControllableTestTicker`).
2. **Layer Isolation:** Game engine domain and state logic are 100% pure Dart, tested in isolation without Flutter widgets, platform channels, or UI harnesses.
3. **High Automation:** All pull requests and development phases must pass `fvm flutter test` and `fvm flutter analyze` with zero warnings or errors.
4. **Platform Parity:** Core layouts and builds are verified on simulated narrow screens (320px) and compiled via `fvm flutter build apk --debug`.

---

## 2. Deterministic Testing Architecture (`ControllableTestTicker`)

Standard asynchronous timers introduce non-determinism, race conditions, and sluggish test execution. BrainForge decouples countdowns and response windows via the `Ticker` contract:

```dart
abstract class Ticker {
  Stream<int> countdown({required int ticks, required Duration interval});
}
```

- **Production:** `RealTicker` leverages `Stream.periodic(interval, ...)` for fluid device execution.
- **Unit Testing:** `ControllableTestTicker` implements synchronous `StreamController<int>(sync: true)` with manual stepping methods:
  - `step()`: Advances the countdown by exactly 1 tick synchronously.
  - `advanceToCompletion()`: Instantly steps through all remaining ticks, triggering completion/timeout callbacks immediately.

This allows multi-second game sequences (e.g. 5-second countdowns or 15-second response limits) to execute deterministically in **less than 1 millisecond** without sleeping.

---

## 3. Test Suite Structure

The test directory is structured as follows:

```
test/
├── helpers/
│   ├── fake_shared_preferences.dart
│   └── test_helper.dart
├── unit/
│   ├── adaptive_difficulty_policy_test.dart         # Pure-Dart promotion, demotion, maintain, threshold boundaries, NaN safety
│   ├── adaptive_difficulty_service_test.dart        # Coordination, write-minimization, profile updates
│   ├── challenge_generator_test.dart                # Seed reproducibility, sequence pools, configs
│   ├── drift_adaptive_difficulty_repository_test.dart# SQLite CRUD, schema v1->v2 migration, data preservation
│   ├── drift_game_attempt_repository_test.dart      # Persistent SQLite attempt storage, aggregation queries
│   ├── game_attempt_repository_test.dart            # In-memory storage, median response times, bests
│   ├── game_config_test.dart                        # Constraint validation, boundary checks, copyWith
│   ├── game_difficulty_test.dart                    # Clamping (1-10), progression, tier naming
│   ├── game_state_machine_test.dart                 # Valid/invalid transitions, gating, timeouts, idempotency
│   ├── game_timer_test.dart                         # Synchronous stepping, pause/resume, countdowns
│   ├── memory_grid_adaptive_integration_test.dart   # Memory Grid + Adaptive service integration, persistence, restart adoption
│   ├── memory_grid_cubit_test.dart                  # Preview pacing, input gating, timeout, pause/resume, attempt saves
│   ├── memory_grid_engine_test.dart                 # Presets, deterministic sequence generation, constraint checks
│   ├── progress_cubit_test.dart                     # Analytics computation, accuracy, median latency, streak calculations
│   ├── scoring_service_test.dart                    # Formula, speed protection, completion scaling
│   ├── settings_cubit_test.dart                     # Theme, audio, and haptic persistence
│   └── theme_test.dart                              # Light/dark palette tokens, contrast, extensions
└── widget/
    ├── app_startup_test.dart                        # App launch, theme hydration, shell rendering
    ├── memory_grid_widget_test.dart                 # Catalog launch, 3x3 board, inputs, results, exit dialog, adaptive banners, narrow screens
    ├── navigation_test.dart                         # 5-tab switching, bottom sheet, 404 fallback
    ├── progress_dashboard_widget_test.dart          # Hero card, metrics cards, empty state, data clearing
    └── theme_switch_test.dart                       # In-app settings toggle reaction
```

---

## 4. Test Execution & Verification

### Running All Automated Tests
```bash
fvm flutter test
```
*Current Status:* **142 / 142 tests passing** (100% pass rate across 22 test suites).

### Running Static Analysis
```bash
fvm flutter analyze
```
*Current Status:* **0 issues found**.

### Code Formatting
```bash
fvm dart format --set-exit-if-changed lib test
```

### Android Debug Build Verification
```bash
fvm flutter build apk --debug
```
*Current Status:* **Built successfully (`app-debug.apk`)**.
