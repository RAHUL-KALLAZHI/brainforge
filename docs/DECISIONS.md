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

---

## ADR 009: Theme Mode and Settings Persistence Architecture

### Context
Users require the ability to toggle between Dark Mode (the default), Light Mode, and System Theme, as well as toggle sound effects and haptic feedback. These preferences must update the UI immediately and survive application restarts.

### Decision
Use `SettingsCubit` managing an immutable `SettingsState`, backed by a dedicated `SettingsRepository` interface implemented via `SharedPreferences`. The repository is registered in `GetIt` during startup and pre-loaded before `runApp`.

### Consequences
- Instant theme and setting toggles throughout the widget tree via `BlocBuilder`.
- Fully testable without physical storage through mockable `SharedPreferences` in unit and widget tests.
- Zero boilerplate in presentation widgets.

---

## ADR 010: Android Toolchain Modernization (AGP 8.6.0, Gradle 8.7, JVM 17 Target)

### Context
Flutter 3.44.5 (Dart 3.12.2) enforces Android Gradle Plugin $\ge 8.6.0$ and Kotlin $\ge 1.9.0$. The default Flutter template used outdated AGP 7.3.0 and Gradle 7.6.3 with Java 1.8 targets, which caused `compileKotlin` failures (`Language version 1.4 is no longer supported` and inconsistent JVM target compatibility).

### Decision
Upgrade the Android build configuration:
- Gradle wrapper: `8.7` (`gradle-8.7-all.zip`)
- Android Gradle Plugin (AGP): `8.6.0`
- Kotlin Android plugin: `1.9.22`
- Compile options & Kotlin options: Aligned to `JavaVersion.VERSION_17` and `jvmTarget = "17"` in `android/app/build.gradle`.

### Consequences
- Clean, error-free Android debug APK compilation.
- Complete compatibility with modern Android 14/15 SDKs and plugins (`shared_preferences_android`).

---

## ADR 011: Pure-Dart Deterministic Adaptive Difficulty Policy with Rolling Window

### Context
Memory Grid and future mini-games must dynamically and gradually adjust their starting challenge level based on verified gameplay performance. The adaptation must avoid erratic single-game fluctuations, protect against accidental exits, maintain deterministic reproducibility, and keep skill assessment strictly decoupled from scoring formulas.

### Decision
Implement `AdaptiveDifficultyPolicy` as an isolated pure-Dart service:
- **Rolling Window:** Evaluates the last 5 attempts, requiring a minimum of 3 eligible attempts before adapting.
- **Eligibility:** Strictly `completed` and `failed` attempts count as evidence. `abandoned` attempts are excluded to prevent skewed metrics.
- **Promotion:** $\ge 3$ eligible attempts, $\ge 90\%$ average accuracy, all attempts completed successfully (no failures/timeouts), and current level $< 10 \implies \text{Level} + 1$.
- **Demotion:** $\ge 3$ eligible attempts, $< 60\%$ average accuracy OR $\ge 2$ consecutive terminal failures, and current level $> 1 \implies \text{Level} - 1$.
- **Boundary Clamping:** Difficulty is clamped between 1 (Beginner) and 10 (Master). Maximum 1 level adjustment per evaluation.
- **Zero Scoring Interference:** Scoring weights (70% accuracy, 20% efficiency, 10% completion) and historical records remain untouched.

### Consequences
- Completely testable in microseconds without database or Flutter dependencies.
- Explainable adaptation rationales displayed to users on the result screen.
- Independent per-game profiles ensure progress in Memory Grid does not alter other games.

---

## ADR 012: Drift SQLite Schema Version 2 Migration & Profile Persistence

### Context
The player's adaptive difficulty level must persist across application restarts. The database must serve as the single source of truth without duplicating state into `shared_preferences`. Adding this persistence must preserve all existing game attempt records from Phase 4.

### Decision
- Create `PlayerGameProfiles` Drift SQLite table with primary key `game_id`, `current_difficulty` integer, `last_action` text, `last_reason` text, and `updated_at` datetime.
- Bump database `schemaVersion` to 2.
- Implement Drift `MigrationStrategy` in `AppDatabase`:
  ```dart
  onUpgrade: (m, from, to) async {
    if (from < 2) {
      await m.createTable(playerGameProfiles);
    }
  }
  ```
- Implement `AdaptiveDifficultyService` write-minimization: updates are written to the database strictly when `hasDifficultyChanged` is true, avoiding redundant disk writes when difficulty is maintained.

### Consequences
- Single local source of truth for game difficulty.
- Seamless, automated schema upgrade for existing installations without data loss.
- High database write efficiency and battery preservation.

---

## ADR 013: Color Echo Multi-Sensory Architecture, Concurrency Guard, and Profile Isolation

### Context
Phase 6.1 introduces Color Echo, the second playable cognitive training mini-game in BrainForge. It requires:
1. Multi-sensory pad differentiation that never relies solely on color (for WCAG AAA / color-blindness accessibility).
2. Repeated symbols in sequences (`allowDuplicates: true`), contrasting with Memory Grid's unique-tile rule.
3. Safe asynchronous preview playback that eliminates race conditions upon user restart or back navigation.
4. Complete isolation of attempt history, adaptive progression profiles, and scoring from Memory Grid.

### Decision
1. **Multi-Sensory Differentiation:** Construct 4 fixed quadrants with distinct base and active illumination states, geometric shapes (Diamond, Hexagon, Star, Circle), and explicit Semantics labels.
2. **Engine & PRNG Reuse:** Use existing pure-Dart `GameEngine<SequenceChallenge, int>` paired with `SeededSequenceGenerator(allowDuplicates: true)` over 4 targets.
3. **Session ID Concurrency Guard:** Protect sequential playback intervals via an integer `_currentSessionId` incremented on every session restart or disposal. Pending asynchronous delays verify `_currentSessionId == sessionId` before mutating state.
4. **Zero-Migration Database Isolation:** Leverage existing Drift tables (`game_attempts` and `player_game_profiles`) which already key on `gameId: String`. Color Echo uses `'color_echo'`, achieving 100% data and adaptive history isolation without modifying the SQLite schema or running migrations.
5. **Phase 5 Result UI Alignment:** Adopt the separated action model: `Continue · Level N` vs. `Proceed to Level N+1` vs. `Replay Level N` vs. `Play Again · Level N`.

### Consequences
- Zero schema changes or database migrations required to add new game modes.
- Memory Grid and Color Echo state, history, and adaptive profiles operate with zero cross-talk.
- Fast restarts and UI pop actions do not leave dangling playback timers or memory leaks.
- 100% testable deterministically using `ControllableTestTicker` and in-memory Drift databases.


