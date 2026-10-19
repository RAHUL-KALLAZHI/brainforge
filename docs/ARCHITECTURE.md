# BrainForge — Architectural Design Specification

## 1. Architectural Philosophy
BrainForge is structured following **Feature-First Layered Architecture** with strict domain decoupling:
- **Zero UI-Coupled Business Logic:** Core game mechanics, challenge generation, timer countdowns, and scoring formulas are pure Dart classes that run without Flutter UI bindings or widget tree dependencies.
- **Offline-First Resilience:** All essential workflows (gameplay, progression, statistics, settings) operate locally without internet or backend dependencies.
- **Predictable State Transitions:** Implemented via `flutter_bloc` (Bloc/Cubit) with immutable state models and Equatable value equality.
- **Replaceable Storage:** The repository pattern isolates data storage details from business logic, permitting future optional cloud synchronization.

---

## 2. Directory Structure

```
lib/
├── main.dart                       # Application entrypoint & dependency bootstrap
├── app/
│   ├── app.dart                    # MaterialApp.router configuration & theme provider
│   ├── router.dart                 # Declarative GoRouter routing tables & ShellRoute
│   └── theme/                      # AppTheme, ColorPalette, Typography, CardStyles
├── core/
│   ├── constants/                  # Route constants, asset keys, storage keys
│   ├── di/                         # Dependency injection container (GetIt)
│   ├── errors/                     # Failure models, AppException hierarchy
│   ├── logging/                    # AppLogger interface (console in debug, silent in prod)
│   ├── navigation/                 # Navigation helpers & transitions
│   ├── storage/                    # Database clients, SharedPreferences wrappers
│   ├── utils/                      # Clock, Random extensions, String formatters
│   └── widgets/                    # Reusable atomic UI: AppButton, AppCard, AppDialog, etc.
├── features/
│   ├── home/                       # Dashboard landing, quick challenge CTA, streak banner
│   │   ├── domain/
│   │   ├── presentation/
│   ├── games/
│   │   ├── shared/                 # Core Game Engine contracts & shared infrastructure
│   │   │   ├── domain/             # GameEngine, GameSessionState, GameResult, GameScore
│   │   │   ├── logic/              # GameBloc, GameTimer, SeededGenerator
│   │   │   └── presentation/       # GameShellScaffold, CountdownOverlay, ResultScreen
│   │   ├── memory_grid/            # Game A: Memory Grid
│   │   ├── color_echo/             # Game B: Color Echo
│   │   ├── focus_hunter/           # Game C: Focus Hunter
│   │   ├── vanishing_cards/        # Game D: Vanishing Cards
│   │   ├── reverse_recall/         # Game E: Reverse Recall
│   │   └── mind_switch/            # Game F: Mind Switch
│   ├── adaptive_engine/            # Independent difficulty evaluation system
│   │   ├── domain/                 # DifficultyProfile, PerformanceMetrics, Policy
│   │   ├── logic/                  # AdaptiveEngine, Evaluator
│   │   └── data/                   # DifficultyHistoryRepository
│   ├── workouts/                   # Daily workout generator & orchestrator
│   ├── progress/                   # Charts, stats aggregations, historical trends
│   ├── rewards/                    # XP, Levels, Badges, Streaks
│   └── settings/                   # Audio, Haptics, Theme, Data Export/Clear
└── shared/
    ├── models/                     # Shared cross-feature DTOs and models
    └── widgets/                    # Common UI components used across features
```

---

## 3. Core Component Architectures

### 3.1. Navigation & Routing Architecture
Navigation uses `go_router` with a root `StatefulShellRoute.indexedStack` to preserve tab state across primary views:
1. `/home` (Home tab)
2. `/games` (Game library catalog)
3. `/workouts` (Daily workout orchestrator)
4. `/progress` (Analytics dashboard)
5. `/settings` (Preferences & data tools)

Modal / Dedicated Fullscreen routes:
- `/games/:gameId/play` (Game session fullscreen without bottom navigation bars)
- `/games/:gameId/result` (Post-game breakdown and reward summary)
- `/workouts/session` (Active daily workout flow)

### 3.2. Shared Game Engine Architecture
Every game adheres to a strict contract:
```dart
abstract class GameEngine<C extends GameChallenge, I extends GameInput> {
  C generateChallenge({required int difficultyLevel, int? seed});
  EvaluationResult evaluateInput(C challenge, I input);
  GameScore computeScore({
    required int difficultyLevel,
    required double accuracy,
    required Duration duration,
    required int completedRounds,
  });
}
```

### 3.2. Shared Game Engine Architecture
The game engine is implemented in pure Dart (`lib/features/games/shared/`), completely decoupled from Flutter widgets, navigation, and persistent database layers.

#### Core Contracts & Models:
- **`GameStatus` (`domain/game_status.dart`)**: Enum capturing lifecycle states: `initial`, `instructions`, `countdown`, `playing`, `paused`, `completed`, `failed`, `abandoned`.
- **`GamePhase` (`domain/game_status.dart`)**: Enum capturing active play phases: `preview`, `input`, `roundFeedback`, `intermission`.
- **`GameDifficulty` (`domain/game_difficulty.dart`)**: Value object enforcing levels 1 to 10 with `.clamped()`, progression step methods (`increase()`, `decrease()`), and tier descriptors (`Beginner`, `Intermediate`, `Advanced`, `Expert`, `Master`).
- **`GameConfig` (`domain/game_config.dart`)**: Immutable configuration with strict validation for `gridRows`, `gridColumns`, `sequenceLength`, `presentationDuration`, `responseTimeLimit`, `distractorCount`, `targetRounds`, `seed`, and `allowDuplicates`.
- **`GameChallenge` (`domain/game_challenge.dart`)**: Abstract base class for round challenges; concrete `SequenceChallenge` models ordered integer sequences.
- **`GameScore` (`domain/game_score.dart`)**: Detailed breakdown containing `accuracy`, `efficiency`, `completion`, and `scaledScore` (clamped 0–1000).
- **`GameResult` (`domain/game_result.dart`)**: Complete summary generated upon terminal session state.
- **`GameAttempt` (`domain/game_attempt.dart`)**: Immutable record for analytics, including median response time calculation.
- **`GameAttemptRepository` (`data/game_attempt_repository.dart`)**: Repository contract with `InMemoryGameAttemptRepository` implementation.

#### State Machine Matrix:
```
[initial]      ──> [instructions] / [countdown] / [abandoned]
[instructions] ──> [countdown] / [abandoned]
[countdown]    ──> [playing] / [abandoned]
[playing]      ──> [paused] / [completed] / [failed] / [abandoned]
[paused]       ──> [playing] / [abandoned]
[completed]    ──> [initial] (via restart)
[failed]       ──> [initial] (via restart)
[abandoned]    ──> [initial] (via restart)
```
- Input is rejected if `isInputAllowed` is false (disallowed during countdown, preview, paused, and terminal states).
- Timeouts immediately mark the session as `failed`; any late input is rejected.
- Successful inputs immediately halt the round response timer, eliminating race conditions.
- Terminal completions are idempotent; multiple trigger calls are ignored.

#### Deterministic Tickers & Clocks:
- Centralized `Ticker` contract decoupling logic from real clocks.
- `RealTicker` uses `Stream.periodic` for production runtime.
- `ControllableTestTicker` uses synchronous streams with manual `step()` and `advanceToCompletion()`, enabling instantaneous, zero-delay unit tests.

#### Standardized Scoring Model:
$$\text{Score} = \text{round}\Big(1000 \times (0.70 \times \text{Accuracy} + 0.20 \times \text{Efficiency} + 0.10 \times \text{Completion})\Big)$$
- **Accuracy:** $\frac{\text{Correct}}{\text{Total Opportunities}}$ clamped to $[0, 1]$.
- **Completion:** $\frac{\text{Completed Rounds}}{\text{Target Rounds}}$ clamped to $[0, 1]$.
- **Efficiency:** Linear interpolation between `targetResponseTime` (1.0) and `maxResponseTime` (0.0).
- **Speed-Gaming Guard:** $\text{Efficiency}_{\text{effective}} = \text{Raw Efficiency} \times \text{Accuracy}$. Rapid incorrect guessing cannot inflate the score.
- Abandoned sessions always yield an overall score of 0.

### 3.3. Adaptive Difficulty Engine
Each of the 6 games maintains an isolated difficulty tracker:
- **Inputs:** Recent history buffer of attempts ($N \ge 5$).
- **Signals:** Average accuracy %, average response latency, completion rate.
- **Rules:**
  - Promotion: $\ge 5$ attempts with $\ge 90\%$ accuracy $\implies \text{Level} + 1$.
  - Retention: $70\% - 89\%$ accuracy $\implies \text{Level unchanged}$.
  - Demotion: $\ge 3$ attempts with $< 70\%$ accuracy $\implies \text{Level} - 1$.
  - Clamping: Minimum Level 1, Maximum Level 10.
- **Explainability:** Returns an immutable `DifficultyEvaluation` object with textual reasoning (e.g., `"Promoted to Level 4: 5 consecutive attempts averaged 94% accuracy"`).

### 3.4. Local Persistence Architecture
- **Engine:** Drift (SQLite) for structured relational queries (attempts, streaks, difficulty logs) + `shared_preferences` for basic flags (dark mode, audio enabled, onboarding completed).
- **Data Isolation:** Repositories accept and return pure domain entities, abstracting all SQL/table mappings.
- **Privacy & GDPR:** Provides `exportAllUserDataAsJson()` and `purgeAllUserData()` operations locally.

---

## 4. Visual Design System Specifications

### 4.1. Color Palette
- **Backgrounds:**
  - Deep Space Navy: `#0B0E17` (App background dark)
  - Surface Card: `#141926` (Primary elevated cards)
  - Surface Border: `#222B40` (Subtle divider / borders)
- **Accents:**
  - Electric Violet: `#7C3AED` (Primary brand & interactive buttons)
  - Neon Cyan: `#06B6D4` (Secondary highlight & active tiles)
  - Restrained Amber: `#F59E0B` (Rewards, stars, streaks)
  - Success Mint: `#10B981` (Correct answers, level ups)
  - Coral Rose: `#EF4444` (Mistakes, timeouts)

### 4.2. Typography & Layout
- Font Stack: Standard Flutter system font hierarchy with consistent weights (Inter / Outfit / System).
- Responsive spacing scale: `4px, 8px, 12px, 16px, 20px, 24px, 32px`.
- Card border radius: `16px` default, `12px` compact, `24px` modal dialogs.
- Reduced Motion: System accessibility reduced-motion flag will bypass rapid tile flashes and complex particle bursts.
