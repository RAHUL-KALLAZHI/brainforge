# BrainForge — Train Your Mind 🧠⚡

BrainForge is a polished, offline-first mobile brain-training application for Android and iOS built using Flutter and Dart. It features adaptive mini-games, daily workouts, skill progression, and detailed performance analytics across visual memory, concentration, sequence recall, pattern recognition, reaction speed, and mental flexibility.

---

## 🚀 Quick Start

### Prerequisites
- [Flutter Version Management (FVM)](https://fvm.app/) installed.
- Target Flutter SDK: **3.44.5** (Dart **3.12.2**), configured via `.fvmrc`.

### Setup & Dependencies
```bash
# Ensure correct Flutter version is active
fvm use 3.44.5

# Install packages
fvm flutter pub get
```

### Running the App
```bash
# Run in debug mode
fvm flutter run

# Run with release mode on device
fvm flutter run --release
```

### Testing & Code Quality
```bash
# Run static analysis
fvm flutter analyze

# Run unit and widget test suite
fvm flutter test
```

---

## 🏛️ Architecture Overview

BrainForge adheres to a **Feature-First Layered Architecture**:
- **Presentation:** Flutter widgets with responsive design, strictly separated from business logic.
- **State Management:** `flutter_bloc` (Bloc/Cubit) with immutable states and `Equatable`.
- **Game Engine:** Pure Dart domain logic and state machines decoupled from Flutter widgets.
- **Navigation:** `go_router` with `StatefulShellRoute` for preserving tab state across the 5 primary destinations (Home, Games, Workouts, Progress, Settings).
- **Persistence:** Local-first using `drift` (SQLite) for structured game telemetry and `shared_preferences` for non-critical toggles.
- **Dependency Injection:** `get_it` service locator.

For in-depth details, see:
- [Architecture Specification](docs/ARCHITECTURE.md)
- [Project Plan & Roadmap](docs/PROJECT_PLAN.md)
- [Architectural Decision Records (ADRs)](docs/DECISIONS.md)
- [Risk Register & Mitigations](docs/RISKS.md)

---

## 🎮 Game Modes
1. **Memory Grid:** Visual sequence memorization and reproduction on an adaptive tile grid.
2. **Focus Hunter:** Speed target search amidst visual distractors.
3. **Vanishing Cards:** Rapid spatial location and symbol recall.
4. **Reverse Recall:** Reverse reproduction of alphanumeric and symbol sequences.
5. **Color Echo:** Multi-sensory sequence reproduction with visual accessibility fallbacks.
6. **Mind Switch:** Cognitive task-switching under dynamic rule changes.

---

## 🔒 Offline & Privacy First
- 100% playable offline without requiring user registration, cloud sync, or network connectivity.
- No personal data or health claims: all statistics are objective in-game performance metrics.
- Complete local data control with data export and wipe features.
