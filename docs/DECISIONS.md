# BrainForge — Architectural Decision Records (ADR)

## ADR 001: Toolchain Management via Flutter Version Management (FVM)

### Context
The host machine has a system-global Flutter SDK installed (`3.22.3`, Dart 3.4.4), whereas the user initialized FVM with Flutter SDK `3.44.5` (Dart 3.12.2). Using inconsistent SDK versions across developer machines or CI causes build anomalies and analyzer discrepancies.

### Decision
Pin Flutter SDK to `3.44.5` using FVM. All toolchain commands (`flutter pub get`, `flutter test`, `flutter analyze`, `flutter run`) will be executed via `fvm flutter ...`. IDE configuration (`.vscode/settings.json`) points `dart.flutterSdkPath` to `.fvm/versions/3.44.5`.

### Consequences
- Reproducible local and CI environments.
- Ensures access to modern Dart 3.x language features and modern Flutter framework APIs.

---

## ADR 002: State Management with `flutter_bloc` and `Equatable`

### Context
BrainForge demands deterministic state transitions across countdowns, sequence presentations, input captures, pausing, and completion events. Complex UI race conditions (such as double taps or timer leaks) must be rigorously prevented.

### Decision
Adopt `flutter_bloc` (Bloc & Cubit) with `equatable`.
- Presentation logic subscribes to immutable state objects.
- Pure state machines for games are expressed as Bloc/Cubit instances with distinct event streams.
- All states extend `Equatable` for reliable equality comparisons without boilerplate.

### Consequences
- Highly testable presentation and domain state.
- Predictable and auditable state flow.
- Separation of concerns: widgets only render UI and dispatch events.

---

## ADR 003: Navigation via `go_router` with `StatefulShellRoute`

### Context
The application features a 5-tab main interface (Home, Games, Workouts, Progress, Settings) plus modal game flows (Game Play, Game Results). Tab state must be preserved during tab switching, while game sessions must run in distraction-free full-screen scaffolds.

### Decision
Adopt `go_router` with a root `StatefulShellRoute.indexedStack` for bottom navigation tabs and standard top-level routes for full-screen game sessions.

### Consequences
- Tab state is preserved when switching between primary tabs.
- Full deep-linking capability and clean back-button handling on Android and iOS.
- Direct path-based route safety and fallback/error screens.

---

## ADR 004: Service Locator via `get_it`

### Context
Repositories, storage adapters, and game engine singletons require clean injection into Blocs and services without tight coupling or cumbersome prop-drilling.

### Decision
Use `get_it` as the centralized service locator (`core/di/injection.dart`). Dependencies are registered in a bootstrap function called during `main()`.

### Consequences
- Easy to swap mock implementations during unit and widget testing.
- Simple, explicit registration order without heavy code generation in early development phases.

---

## ADR 005: Local Storage via Drift (SQLite) & SharedPreferences instead of Isar

### Context
The prompt allows selecting between Isar and a maintained alternative like Drift with SQLite:
> "Use a persistent local database such as Isar if its current maintenance status and compatibility with the project's Flutter and Dart versions are satisfactory. Otherwise, select a maintained compatible database such as Drift with SQLite and document the decision."

Investigation shows:
- `isar` (v3.1.0+1) has had stalled maintenance, unmaintained C++ binaries, and compatibility issues with recent Flutter releases and newer iOS/Android toolchains.
- `drift` (with `sqlite3_flutter_libs`) is actively maintained, battle-tested across iOS, Android, macOS, Linux, and Windows, has first-class migration support, and handles complex analytical aggregations (averages, percentiles, date windows) efficiently in SQL.
- `shared_preferences` is ideal for lightweight key-value flags (theme preference, mute audio, haptic toggle).

### Decision
Use `drift` (SQLite) for structured game attempt logs, workout sessions, difficulty history, and progression records. Use `shared_preferences` for non-critical device preferences.

### Consequences
- Guaranteed stability with Flutter 3.44.5 and upcoming Dart versions.
- Safe schema migrations and rich relational queries for the Progress Analytics Dashboard.
- Zero risk of native compilation failures from unmaintained C bindings.

---

## ADR 006: Offline Font and Asset Strategy

### Context
BrainForge must operate 100% offline from the very first launch. The `google_fonts` package attempts to fetch fonts over HTTP by default if font files are not explicitly packaged into assets, which breaks offline-first guarantees and introduces network permissions.

### Decision
Rely on standard system font fallbacks with curated typography scales, or bundle exact font assets directly into `assets/fonts/` without runtime network fetches.

### Consequences
- 100% offline predictability.
- No network permissions required for typography.
- Zero layout shift or font flickering on launch.

---

## ADR 007: Pure Dart Game Engine Decoupled from Widgets

### Context
Game logic (tile selection, timer calculations, sequence verification, score weighting) should be fast, reliable, and testable without the overhead of pumping widgets or simulating Flutter UI frames.

### Decision
All game logic resides in pure Dart classes (`GameEngine`, `GameChallenge`, `GameScore`). Flutter widgets merely listen to the state emitted by the Bloc and render the corresponding visuals.

### Consequences
- 100% unit test coverage of game logic with microsecond execution times.
- Zero Flutter framework dependencies in domain business logic.
- Robust against UI refactoring or redesigns.

---

## ADR 008: Deterministic PRNG Seed Challenge Generation

### Context
Debugging unexpected game layouts or comparing players' performance requires reproducible challenge sequences.

### Decision
Game challenge generation accepts an optional integer `seed` (using Dart's `math.Random(seed)`). Daily workouts use the date integer (e.g. `20261019`) as the seed so that all players encounter identical daily challenges for fair competition.

### Consequences
- Guaranteed test reproducibility across test runs.
- Daily workout consistency across all users on any given date.
