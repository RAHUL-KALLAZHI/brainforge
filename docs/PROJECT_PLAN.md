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

### Phase 3: Memory Grid MVP
- [ ] Implement Memory Grid challenge logic ($N \times M$ grid, highlighted sequence, timing parameters).
- [ ] Build presentation layer: responsive grid widget, tile lighting animations, sequence reveal controller.
- [ ] Enforce strict state gating: touch inputs ignored during sequence playback.
- [ ] Build Game Summary Screen displaying accuracy, response times, score, and replay/next actions.
- [ ] Wire attempt recording to in-memory/preliminary persistence.
- [ ] Implement accessible visual indicators (high contrast pulse, shape/number support).
- [ ] Unit and widget tests covering boundary cases (rapid taps, timeout, sequence mismatches).

### Phase 4: Local Database and Progress Persistence
- [ ] Integrate chosen database engine (Drift SQLite) and lightweight storage (`shared_preferences`).
- [ ] Define schemas: `GameAttemptsTable`, `DailyWorkoutsTable`, `PlayerStatsTable`, `DifficultyHistoryTable`, `AchievementsTable`.
- [ ] Implement clean repository layer with clear abstraction: `GameRepository`, `UserRepository`, `SettingsRepository`.
- [ ] Write database migrations framework and automated migration tests.
- [ ] Implement aggregation queries: accuracy by game, median response time, streak computations.
- [ ] Provide data wipe/export features for user privacy compliance.

### Phase 5: Adaptive Difficulty Engine
- [ ] Build `AdaptiveEngine` with domain models: `DifficultyProfile`, `DifficultyParameters`, `EvaluationResult`.
- [ ] Implement independent game tracking (Game A memory difficulty does not alter Game C attention difficulty).
- [ ] Rule engine:
  - Promote (+1 step): $\ge 5$ recent attempts with $\ge 90\%$ average accuracy.
  - Maintain: $70\% - 89\%$ average accuracy.
  - Demote (-1 step): $\ge 3$ recent attempts with $< 70\%$ average accuracy.
  - Clamp between Min and Max level boundaries.
- [ ] Ensure full audit trail: explainable reason strings stored with every level adjustment.
- [ ] Unit tests for cold start, streak promotions, boundary clamps, and noisy erratic scores.

### Phase 6: Additional Game Modes
- [ ] **Game C: Focus Hunter** (Target identification among visually similar distractors).
- [ ] **Game D: Vanishing Cards** (Brief exposure of card layouts, recall location/symbol).
- [ ] **Game E: Reverse Recall** (Sequence reproduction in reverse order or transformed order).
- [ ] **Game B: Color Echo** (Multi-sensory Simon-style sequence with sound + visual fallback).
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
