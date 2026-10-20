# BrainForge — Project Plan & Roadmap

## 1. Project Overview & Product Vision
**BrainForge** is an offline-first, commercially viable mobile cognitive training application built with Flutter and Dart for Android and iOS. It targets adults and young adults who want focused, scientifically grounded (without medical or pseudoscientific cognitive-enhancement claims) training in:
- Visual and working memory
- Concentration and selective attention
- Sequence recall
- Pattern recognition
- Reaction time and processing speed
- Mental flexibility and rule-switching

### Core Session Formats:
1. **Quick Challenge:** 3–5 minute focused single-game sprints.
2. **Daily Workout:** 8–12 minute curated, balanced multi-game sessions.
3. **Practice Mode:** On-demand, self-paced gameplay with configurable difficulty.

---

## 2. Phase-Wise Development Roadmap

| Phase | Title | Status | Primary Focus |
|---|---|---|---|
| **Phase 0** | **Repository Inspection & Project Plan** | **Complete** | Workspace inspection, toolchain alignment (FVM), architecture, risk register, baseline analysis & testing. |
| **Phase 1** | **Flutter Foundation & Design System** | **Complete** | Feature-first architecture, Dark/Light theme, navigation shell (`go_router`), DI (`get_it`), base UI kit, linting. |
| **Phase 2** | **Shared Game Engine** | Ready for execution | Game contract, deterministic seed challenge generator, state machines, countdown/timer services, scoring interfaces. |
| **Phase 3** | **Memory Grid MVP** | Pending | First fully playable game (Memory Grid), sequence animations, feedback loop, attempts persistence, audio/visual cues. |
| **Phase 4** | **Local Database & Progress Persistence** | Pending | Persistent storage (Drift SQLite), repositories, history queries, migrations, offline data isolation. |
| **Phase 5** | **Adaptive Difficulty Engine** | Pending | Independent game difficulty policies, rolling metric evaluation, explainable promotion/demotion engine. |
| **Phase 6** | **Additional Game Modes** | Pending | Focus Hunter, Vanishing Cards, Reverse Recall, Color Echo, Mind Switch built on shared engine. |
| **Phase 7** | **Daily Workouts & Analytics Dashboard** | Pending | Multi-game workout orchestrator, streak tracking, accuracy/trend charts, performance dashboard. |
| **Phase 8** | **Rewards & Retention** | Pending | XP curves, level progressions, achievements, daily/weekly missions, local notifications. |
| **Phase 9** | **UX Polish, Accessibility & Optimization** | Pending | Screen reader semantics, reduced-motion adaptations, frame profiling, responsive tablet layouts. |
| **Phase 10** | **Commercialization & Optional Cloud** | Pending | Store-compliant IAP/entitlements, paywalls, optional backup sync architecture. |
| **Phase 11** | **QA, Release Preparation & Release** | Pending | Comprehensive test suites, release signing workflows, App Store & Google Play metadata. |

---

## 3. Phase Detailed Breakdown & Acceptance Criteria

### Phase 0: Repository Inspection and Project Plan (Complete)
- [x] Inspect workspace structure, Git status, and IDE settings.
- [x] Verify toolchain: FVM Flutter 3.44.5 (Dart 3.12.2) vs system Flutter 3.22.3 (Dart 3.4.4).
- [x] Verify Android configuration (AGP 7.3.0, Gradle 7.6.3, namespace `com.example.brainforge`).
- [x] Verify iOS configuration (Deployment target 12.0, bundle ID `com.example.brainforge`).
- [x] Verify existing test and analyzer suites pass without errors.
- [x] Run dry-run package compatibility tests for core dependencies.
- [x] Produce architecture documentation (`docs/ARCHITECTURE.md`), decisions log (`docs/DECISIONS.md`), risk register (`docs/RISKS.md`), and updated `README.md`.
- [x] Propose exact Phase 1 implementation sequence.

### Phase 1: Flutter Foundation and Design System (Complete)
- [x] Configure `pubspec.yaml` with vetted dependencies: `flutter_bloc`, `equatable`, `go_router`, `get_it`, `shared_preferences`.
- [x] Establish feature-first directory layout under `lib/` (`app/`, `core/`, `features/`).
- [x] Configure dependency injection container (`core/di/injection.dart`).
- [x] Implement declarative routing (`app/router.dart`) with `StatefulShellRoute.indexedStack` for bottom navigation and error screen (`NotFoundScreen`) for invalid deep links.
- [x] Build Design System (`core/theme/` and `core/constants/`):
  - Palette: Deep Space Navy (`#0B0E17`), Surface Card (`#141926`), Electric Violet (`#7C3AED`), Cyan Pulse (`#06B6D4`), Amber (`#F59E0B`).
  - Typography, standard spacing scales, rounded surfaces (`8px`, `12px`, `16px`, `24px`).
  - Common UI components: `AppButton`, `AppCard`, `AppHeader`, `AppChip`, `LoadingIndicator`.
- [x] Implement Main Navigation Shell with 5 destinations:
  1. Home (Branding, Welcome header, prominent Daily Workout card with Start Workout CTA, preview cards, progress empty state)
  2. Games (Selection cards for all 6 planned cognitive games with domain tags and roadmap details)
  3. Daily Workout (Introductory session format overview with navigation routes back to Home and Games)
  4. Progress (Objective analytics dashboard with informative empty state and domain breakdown)
  5. Settings (Interactive theme mode switching, sound toggle, haptic toggle, persisted via SharedPreferences)
- [x] Verify responsive layouts on standard and narrow (320px width) screens without RenderFlex overflows.
- [x] Static analysis passes with 0 issues (`fvm flutter analyze`).
- [x] Comprehensive automated unit and widget test suite passes 18/18 tests (`fvm flutter test`).
- [x] Debug Android APK builds successfully (`fvm flutter build apk --debug`).

### Phase 2: Shared Game Engine (Complete)
- [x] Establish abstract domain contracts (`GameEngine`, `GameChallenge`, `GameScore`, `GameResult`, `GameAttempt`, `GameSessionState`).
- [x] Implement robust `GameStateMachine` with strict transition matrix, input gating, idempotency guards, and error handling.
- [x] Implement deterministic `GameTimer` and `Ticker` service (`RealTicker` and `ControllableTestTicker` for instant, non-flaky test execution).
- [x] Build seeded, reproducible challenge generator (`ChallengeGenerator`, `SeededSequenceGenerator`) with parameter validation.
- [x] Implement pure-Dart `ScoringService`:
  - $\text{Score} = 1000 \times (0.70 \times \text{Accuracy} + 0.20 \times \text{Efficiency} + 0.10 \times \text{Completion})$.
  - Speed-guessing protection: efficiency scaled by accuracy so rapid incorrect answers yield zero speed points.
- [x] Create attempt recording model (`GameAttempt`) and repository contract (`GameAttemptRepository`, `InMemoryGameAttemptRepository`).
- [x] Handle pause, resume, app backgrounding, safe abandonment, and double-completion protection.
- [x] 100% unit test coverage for pure-Dart engine: 68 total tests passing, 0 analyzer issues, Android debug build verified.

### Phase 3: Memory Grid MVP (Complete)
- [x] Implement Memory Grid challenge logic ($N \times M$ grid from 3x3 to 5x5, highlighted sequences 3 to 10, validated presets across Levels 1–10).
- [x] Build presentation layer: responsive grid widget (`MemoryGridBoard`), tactile animated tiles (`MemoryGridTile`), sequence reveal controller.
- [x] Enforce strict state gating: touch inputs ignored during instructions, countdown, and sequence playback.
- [x] Build Game Result Screen (`MemoryGridResultView`) displaying accuracy, scaled score, duration, sequence length, and Play Again / Return actions.
- [x] Wire attempt recording to `GameAttemptRepository` (saved exactly once upon terminal completion, failure, or abandonment).
- [x] Implement accessible visual indicators (high contrast pulses, checkmark/error badge icons, semantically labeled tiles, screen reader hints).
- [x] Exit confirmation modal during active play to prevent accidental score loss or abandoned sessions.
- [x] 100% test coverage across engine, Cubit, and presentation widgets: 88 total automated tests passing (20 new tests in Phase 3), 0 analyzer issues, Android debug build verified.

### Phase 4: Local Database and Progress Persistence (Complete)
- [x] Integrate chosen database engine (Drift SQLite via `drift` & `drift_flutter`) and lightweight storage (`shared_preferences`).
- [x] Define schema: `GameAttemptsTable` with indexing on `(game_id, completed_at)` and robust converters for integer list latencies.
- [x] Implement clean repository layer with clear abstraction: `GameAttemptRepository`, `SettingsRepository`, `DriftGameAttemptRepository`.
- [x] Write database unit tests and schema verification.
- [x] Implement aggregation queries: accuracy by game, median response time, calendar day streak computations.
- [x] Deliver initial Progress Dashboard screen with Hero overview, reactive state management via `ProgressCubit`, and empty state handling.
- [x] 107 automated tests passing, 0 analyzer issues, physical device verification.

### Phase 5: Adaptive Difficulty Engine (Complete)
- [x] Build pure-Dart deterministic adaptation policy (`AdaptiveDifficultyPolicy`) and domain models (`AdaptationAction`, `AdaptationDecision`, `AdaptivePolicyConfig`, `PlayerGameProfile`).
- [x] Implement per-game isolation (Memory Grid difficulty tracked independently in database).
- [x] Deterministic rule engine:
  - Rolling window of last 5 attempts, requiring minimum 3 eligible attempts.
  - Promote (+1 step): $\ge 3$ eligible attempts with $\ge 90\%$ average accuracy, all completed (no failures/timeouts).
  - Demote (-1 step): $\ge 3$ eligible attempts with $< 60\%$ average accuracy or $\ge 2$ consecutive failures.
  - Maintain: intermediate performance, insufficient history (<3), or boundary limits.
  - Clamp between Min (1) and Max (10) boundaries; maximum 1-level adjustment per decision.
- [x] Ensure explainable reason strings stored with every level adjustment.
- [x] Drift SQLite database schema migration from version 1 to 2 (`PlayerGameProfilesTable`), preserving existing game records.
- [x] Write-minimizing `AdaptiveDifficultyService` (database updates occur strictly when effective level changes).
- [x] Memory Grid end-to-end integration: loads effective difficulty on startup, adapts only after successful attempt save, displays promote/demote banners, adopts adapted level on Play Again.
- [x] Progress Dashboard displays recommended Memory Grid difficulty.
- [x] 142 automated tests passing, 0 analyzer issues, Android debug build verified.

### Phase 6: Additional Game Modes

#### Phase 6.1: Color Echo (Complete)
- [x] Pure-Dart engine logic reusing `GameEngine<SequenceChallenge, int>` with `SeededSequenceGenerator(allowDuplicates: true)`.
- [x] 4 multi-sensory color pads (Cyan, Violet, Amber, Green) with distinct shapes, neon active illuminations, and accessibility semantics.
- [x] Standardized 1–10 difficulty scaling: sequence lengths 3 to 12, presentation durations 800ms to 350ms, gaps 200ms to 100ms.
- [x] State machine input gating during countdown and playback preview.
- [x] Drift SQLite persistence via `GameAttemptRepository` using unique `'color_echo'` game ID.
- [x] Adaptive difficulty integration isolated from Memory Grid; 3 qualifying wins (≥90% accuracy) required for promotion.
- [x] Results screen UX adhering to Phase 5 standards: Continue, Proceed to Next Level, Replay, Return to Game.
- [x] Catalog integration: "Playable" badge and modal launching `/games/color-echo`.
- [x] Comprehensive test suite: 36 new automated tests (11 unit engine, 11 unit cubit, 5 adaptive integration, 9 widget), bringing project total to 200 passing tests with 0 analyzer issues.

#### Phase 6.2+: Upcoming Game Modes (Pending)
- [ ] **Game C: Focus Hunter** (Target identification among visually similar distractors).
- [ ] **Game D: Vanishing Cards** (Brief exposure of card layouts, recall location/symbol).
- [ ] **Game E: Reverse Recall** (Sequence reproduction in reverse order or transformed order).
- [ ] **Game F: Mind Switch** (Task-switching cognitive flexibility with dynamic rule changes).
- [ ] Unit and widget test suite for each mode.

### Phase 7: Daily Workouts and Progress Dashboard
- [ ] Daily Workout generator (picks 3–4 games based on target cognitive domains).
- [ ] Workout session orchestrator with step progression and interruption resumption.
- [ ] Interactive Progress Dashboard:
  - Radar or categorical breakdown (Memory, Attention, Speed, Flexibility).
  - Historical score charts and median reaction time over time.
  - Personal bests and milestones.
  - Empty states with informative onboarding guidance.

### Phase 8: Rewards and Retention
- [ ] XP and player leveling curves.
- [ ] Streak calculation engine utilizing local calendar dates (robust to midnight boundaries).
- [ ] Achievement engine with celebratory unlock modals.
- [ ] Daily and weekly mission tracker.
- [ ] Local scheduled notifications for daily workout reminders (permission gated).

### Phase 9: UX Polish, Accessibility, and Performance
- [ ] Semantics and screen reader compatibility across all games.
- [ ] Reduced-motion setting (disable fast flashes/shakes).
- [ ] Audio & haptics feedback toggles.
- [ ] Frame rate profiling (ensure steady 60/120 fps animations on mid-range devices).
- [ ] Memory leak checks (verify controllers, timers, streams dispose properly).

### Phase 10: Commercialization & Optional Cloud Backend
- [ ] Define In-App Purchase product catalog (BrainForge Pro: unlimited workouts, deep analytics, theme pack).
- [ ] Offline-first entitlement architecture with secure state verification.
- [ ] Clean paywall presentation respecting store guidelines.
- [ ] Optional cloud sync design (Firebase / Supabase adapter) kept strictly decoupling the offline MVP.

### Phase 11: QA, Release Preparation, and Release
- [ ] Automated CI test matrix run (unit, widget, integration).
- [ ] Android release build verification (App Bundle, ProGuard/R8 verification, signing guide).
- [ ] iOS release build verification (Xcode Archive, test signing).
- [ ] Privacy policy, App Store privacy nutritional labels, and release checklist.
