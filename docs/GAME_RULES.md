# BrainForge — Game Rules & Engine Mechanics

This document specifies the core game mechanics, scoring formulations, and state machine transitions governing cognitive training mini-games within BrainForge.

---

## 1. Shared Engine Architecture

The game engine is implemented in pure Dart (`lib/features/games/shared/`), completely isolated from UI rendering and navigation. All mini-games conform to common lifecycle transitions, deterministic tickers, and standardized scoring contracts.

### 1.1 State Machine Lifecycle & Transitions

Each game session progresses through a finite state machine:

```
[initial]
   │
   ├──> [instructions]
   │         │
   │         └──> [countdown] (3..2..1)
   │                   │
   └──> [countdown] ───┘
             │
             └──> [playing]
                    ├── (setPhase: preview / input / feedback)
                    ├── [paused] <──> [playing]
                    ├── [completed]
                    ├── [failed]
                    └── [abandoned]
```

#### Valid Transitions:
- `initial` $\to$ `instructions`, `countdown`, `abandoned`
- `instructions` $\to$ `countdown`, `abandoned`
- `countdown` $\to$ `playing`, `abandoned`
- `playing` $\to$ `paused`, `completed`, `failed`, `abandoned`
- `paused` $\to$ `playing`, `abandoned`
- Terminal states (`completed`, `failed`, `abandoned`) $\to$ `initial` (only via `restart()`)

#### Invariants & Safety Guarantees:
- **Input Gating:** `recordInput()` returns `false` and ignores actions unless `status == playing` and `phase == input`.
- **Double Completion Guard:** `completeSession()`, `failSession()`, and `abandonSession()` are idempotent. Redundant calls cannot duplicate rewards, increment XP, or trigger extra database entries.
- **Race Condition Elimination:** Player input instantly cancels the round response timer. Late timeouts cannot trigger after an input evaluation.
- **Lifecycle Backgrounding:** When the app is backgrounded or navigated away, invoking `pause()` freezes the active gameplay stopwatch and suspends all ticker subscriptions.

---

## 2. Standardized Scoring System

Every mini-game computes performance using a normalized composite formula bounded between 0 and 1,000 points:

$$\text{Score} = \text{round}\Big(1000 \times \big(0.70 \times \text{Accuracy} + 0.20 \times \text{Efficiency} + 0.10 \times \text{Completion}\big)\Big)$$

### 2.1 Score Component Definitions

1. **Accuracy (Weight: 70%)**
   $$\text{Accuracy} = \frac{\text{Correct Actions}}{\text{Total Opportunities}} = \frac{\text{Correct}}{\text{Correct} + \text{Incorrect} + \text{Missed}}$$
   Bounded strictly to $[0.0, 1.0]$.

2. **Completion (Weight: 10%)**
   $$\text{Completion} = \frac{\text{Completed Rounds}}{\text{Target Rounds}}$$
   Bounded strictly to $[0.0, 1.0]$.

3. **Efficiency (Weight: 20%)**
   Evaluates response speed without penalizing careful deliberation:
   $$\text{Raw Efficiency} = \begin{cases} 
   1.0 & \text{if } \bar{t} \le t_{\text{target}} \\
   0.0 & \text{if } \bar{t} \ge t_{\text{max}} \\
   \frac{t_{\text{max}} - \bar{t}}{t_{\text{max}} - t_{\text{target}}} & \text{otherwise}
   \end{cases}$$
   where $\bar{t}$ is the average response latency per opportunity. Default parameters are $t_{\text{target}} = 2.0\text{s}$ and $t_{\text{max}} = 10.0\text{s}$.

4. **Speed-Gaming Guard (Anti-Exploit)**
   $$\text{Efficiency}_{\text{effective}} = \text{Raw Efficiency} \times \text{Accuracy}$$
   *Rule:* Fast guessing must **never** yield a high score. If accuracy is 0%, effective efficiency is 0%, regardless of how rapidly inputs were submitted.

5. **Abandonment Guard**
   If a user exits or abandons a game session before resolution, the final score is clamped to **0 points**.

---

## 3. Seeded Challenge Generation & Determinism

All challenge generators implement `ChallengeGenerator<C>`:
- **Reproducibility:** A challenge created with `seed: S` and `roundIndex: R` produces the exact same sequence across devices and executions.
- **Independent Seeds:** Games instantiate dedicated PRNG instances (`Random(config.seed ^ (roundIndex * 31))`) and never rely on shared global random instances.
- **Modes Supported:**
  - `allowDuplicates: false`: For tile recall games (Memory Grid, Vanishing Cards) where items in a sequence must be distinct.
  - `allowDuplicates: true`: For pattern repeating games (Color Echo) where symbols can recur multiple times in sequence.

---

## 4. Planned Game Configurations

| Game ID | Cognitive Domain | Grid / Pool | Sequence Length | Time Limit | Duplicate Rule |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `memory_grid` | Visual & Working Memory | $3 \times 3$ to $5 \times 5$ | $3 + \text{Level}$ | $15\text{s}$ | Unique tiles |
| `color_echo` | Working Memory & Audio-Visual | 4 quadrants | $3 + \text{Level}$ | $15\text{s}$ | Repeatable |
| `focus_hunter` | Selective Attention | Variable targets | Distractor-based | $10\text{s}$ | Dynamic targets |
| `vanishing_cards`| Spatial Memory | $3 \times 3$ cards | Cards fade out | $12\text{s}$ | Unique cards |
| `reverse_recall`| Sequence Manipulation | Numeric sequence | $3 + \text{Level}$ | $20\text{s}$ | Inverted order |
| `mind_switch` | Cognitive Flexibility | Stroop task pool | Dual conditions | $5\text{s}$ | Rapid alternation |

---

## 5. Persistence Contracts (Phase 2 $\to$ Phase 4 Bridge)

Phase 2 defines `GameAttemptRepository`:
- `saveAttempt(GameAttempt attempt)`: Records timestamped attempt with accuracy, correct/incorrect/missed counts, and response latency list.
- `getAttempts({required String gameId, int limit})`: Retrieves history latest first.
- `getPersonalBest(String gameId)`: Returns highest scoring attempt for that game.
- `getRecentAttempts({required String gameId, int count})`: Supplies recent history buffer for Phase 5's adaptive difficulty engine.

Phase 2 ships with `InMemoryGameAttemptRepository`. Phase 4 will replace the underlying implementation with Drift SQLite persistence without changing this domain contract.

---

## 6. Memory Grid Gameplay Mechanics (Phase 3 MVP)

Memory Grid tests visual working memory, spatial encoding, and sequential recall.

### 6.1 Gameplay Flow

1. **Ready Screen:** Player configures difficulty (Level 1–10) and reviews training instructions.
2. **Pre-Game Countdown:** A 3-second countdown (`3.. 2.. 1..`) prepares the player. Input is strictly disabled.
3. **Sequence Preview:** Designated grid tiles illuminate sequentially (electric cyan pulse for 750ms with 150ms gap). All touch inputs remain gated off during playback.
4. **Recall / Input Phase:** Touch inputs activate. A 15-second countdown timer initiates. Player must tap tiles in the exact sequence order.
5. **Immediate Feedback:**
   - Correct tap: Tile flashes cyan with a checkmark badge; sequence step index increments.
   - Incorrect tap: Tile flashes error red with an X badge; session immediately enters `GameStatus.failed`.
6. **Session Resolution:**
   - **Success (`GameStatus.completed`):** All sequence tiles correctly reproduced in order. Composite score calculated via `ScoringService`.
   - **Failure (`GameStatus.failed`):** Incorrect tile selected or response time window expired (15s). Recorded with actual partial correct/incorrect counts.
   - **Abandonment (`GameStatus.abandoned`):** Back navigation during active play triggers exit confirmation. Confirming records attempt with 0 score.
7. **Attempt Recording:** Every resolved session saves exactly one `GameAttempt` to `GameAttemptRepository`. Redundant rebuilds and double-taps cannot record duplicate attempts.

### 6.2 Difficulty Mapping (Levels 1 to 10)

| Difficulty Level | Tier Name | Grid Size | Total Tiles | Sequence Length | Presentation Duration | Time Limit |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Level 1** | Beginner | $3 \times 3$ | 9 | 3 | 750ms | 15s |
| **Level 2** | Beginner | $3 \times 3$ | 9 | 4 | 750ms | 15s |
| **Level 3** | Intermediate | $3 \times 3$ | 9 | 5 | 750ms | 15s |
| **Level 4** | Intermediate | $4 \times 4$ | 16 | 5 | 750ms | 15s |
| **Level 5** | Advanced | $4 \times 4$ | 16 | 6 | 750ms | 15s |
| **Level 6** | Advanced | $4 \times 4$ | 16 | 7 | 750ms | 15s |
| **Level 7** | Expert | $5 \times 5$ | 25 | 7 | 750ms | 15s |
| **Level 8** | Expert | $5 \times 5$ | 25 | 8 | 750ms | 15s |
| **Level 9** | Master | $5 \times 5$ | 25 | 9 | 750ms | 15s |
| **Level 10** | Master | $5 \times 5$ | 25 | 10 | 750ms | 15s |

---

## 7. Adaptive Difficulty System (Phase 5)

The adaptive difficulty system continuously tracks player performance and adjusts the effective starting challenge level to provide an optimal cognitive training zone (preventing boredom at low levels and excessive frustration at high levels).

### 7.1 Decision Window & Eligible Attempts
- **Rolling Window Size:** Last 5 attempts (`windowSize = 5`).
- **Minimum Required History:** At least 3 eligible attempts (`minRequiredAttempts = 3`) are required before any adjustment can be made.
- **Eligible Statuses:** Only `GameStatus.completed` and `GameStatus.failed` attempts count as valid performance evidence.
- **Excluded Statuses:** `GameStatus.abandoned` sessions are excluded from performance calculations to ensure incomplete attempts or accidental exits do not distort skill assessments.

### 7.2 Decision Rules & Thresholds

| Action | Conditions | Target Effect |
| :--- | :--- | :--- |
| **Promote** | $\ge 3$ eligible attempts, **$\ge 90\%$ average accuracy**, all attempts successfully completed (`status == completed`), and $\text{Level} < 10$. | $\text{Level} + 1$ (Gradual 1-step increase) |
| **Demote** | $\ge 3$ eligible attempts, **$< 60\%$ average accuracy** OR **$\ge 2$ consecutive failures**, and $\text{Level} > 1$. | $\text{Level} - 1$ (Gradual 1-step decrease) |
| **Maintain** | Performance between 60% and 89%, isolated single failure with adequate accuracy, or level boundaries reached (clamped at 1 and 10). | $\text{Level}$ remains unchanged |
| **Insufficient Data** | Fewer than 3 eligible attempts recorded in history. | $\text{Level}$ remains unchanged (initial baseline Level 1) |

### 7.3 Boundary & Safety Invariants
- **Strict Clamping:** Difficulty is bounded strictly between Level 1 (Beginner) and Level 10 (Master). Players at Level 10 cannot be promoted; players at Level 1 cannot be demoted.
- **Gradual Adjustment:** A single evaluation decision can adjust difficulty by at most 1 level. Difficulty never jumps multiple levels in a single game.
- **Idempotency & Replay Safety:** Identical inputs yield identical decisions. Re-evaluating after a completed attempt does not trigger duplicate adjustments.
- **Write Minimization:** Persistent profile database writes occur strictly when the effective difficulty level actually changes.
- **Decoupled Scoring:** Historical scores, earned points, and leaderboards remain untouched. Skill assessment governs only future session challenge generation.
- **Independent Game Profiles:** Adaptive progression in Memory Grid does not alter difficulty in any other game mode.

---

## 8. Color Echo Gameplay Mechanics (Phase 6.1)

Color Echo tests working memory, audio-visual pattern recognition, and sustained sequential focus through an electronic pattern-reproduction mechanic.

### 8.1 4-Pad Audio-Visual Matrix

Color Echo uses a fixed 2×2 quad-pad matrix with multi-sensory differentiation so state never depends on color alone:

| Pad Index | Pad Name | Base Color | Active Illumination | Shape / Icon | Accessibility Semantic |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **0** | **Cyan** | `0x3300E5FF` (dark cyan) | `0xFF00E5FF` (neon electric cyan) | Diamond (`Icons.diamond_rounded`) | Cyan Diamond pad, Upper-left |
| **1** | **Violet** | `0x337C4DFF` (dark violet) | `0xFF7C4DFF` (vivid violet) | Hexagon (`Icons.hexagon_rounded`) | Violet Hexagon pad, Upper-right |
| **2** | **Amber** | `0x33FFAB00` (dark amber) | `0xFFFFAB00` (bright amber) | Star (`Icons.star_rounded`) | Amber Star pad, Lower-left |
| **3** | **Green** | `0x3300E676` (dark emerald) | `0xFF00E676` (neon emerald green) | Circle (`Icons.circle_rounded`) | Green Circle pad, Lower-right |

### 8.2 Gameplay Flow & Input Gating

1. **Ready Screen:** Displays instructions, multi-sensory pad preview, starting difficulty slider (Levels 1–10), and a Start Game action.
2. **Countdown:** A deterministic 3-second countdown (`3.. 2.. 1..`). Pad inputs are strictly disabled.
3. **Sequence Preview (Playback):**
   - Pads illuminate sequentially with their active neon tint, 3.5px white border, and 24px colored drop shadow glow.
   - Sequence allows duplicate consecutive or repeated colors (`allowDuplicates: true`).
   - Touch inputs remain strictly locked (`isInputAllowed == false`).
   - Asynchronous playback handles session cancellation safely via incrementing session IDs.
4. **Interactive Recall (Input Phase):**
   - Illuminations extinguish, and player input unlocks (`isInputAllowed == true`).
   - A 15-second response countdown begins.
   - Pad taps provide instant tactile feedback (bright active flash).
   - Correct tap: Increments player sequence step; progress header updates (`Echo: X of N pads`).
   - Incorrect tap: Highlights error; immediately resolves session as `GameStatus.failed`.
5. **Terminal Resolution & Scoring:**
   - **Success (`GameStatus.completed`):** Entire sequence accurately reproduced. Composite score calculated via standard `ScoringService`.
   - **Failure (`GameStatus.failed`):** Incorrect pad tapped or time limit expired. Attempt persisted with actual correct count and 0% accuracy.
   - **Abandonment (`GameStatus.abandoned`):** Back navigation during active play prompts confirmation dialog. If confirmed, saved as abandoned with score clamped to 0.
6. **Results & Adaptive Progression:**
   - Standard action semantics:
     - Promoted: `Proceed to Level N+1`, `Replay Level N`, `Return to Game`.
     - Normal win: `Continue · Level N`, `Return to Game`.
     - Failure: `Play Again · Level N`, `Return to Game`.

### 8.3 Difficulty Mapping (Levels 1 to 10)

| Difficulty Level | Tier Name | Sequence Length | Presentation Duration | Gap Duration | Response Limit |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Level 1** | Beginner | 3 | 800ms | 200ms | 15s |
| **Level 2** | Beginner | 4 | 750ms | 180ms | 15s |
| **Level 3** | Intermediate | 5 | 700ms | 170ms | 15s |
| **Level 4** | Intermediate | 6 | 650ms | 160ms | 15s |
| **Level 5** | Advanced | 7 | 600ms | 150ms | 15s |
| **Level 6** | Advanced | 8 | 550ms | 140ms | 15s |
| **Level 7** | Expert | 9 | 500ms | 130ms | 15s |
| **Level 8** | Expert | 10 | 450ms | 120ms | 15s |
| **Level 9** | Master | 11 | 400ms | 110ms | 15s |
| **Level 10** | Master | 12 | 350ms | 100ms | 15s |

### 8.4 Persistence & Adaptive Isolation

- **Game Identifier:** Stored as `'color_echo'` in `game_attempts` and `player_game_profiles`.
- **Profile Isolation:** Evaluated independently by `AdaptiveDifficultyService`. Memory Grid history never influences Color Echo, and vice-versa.
- **Progression Contract:** Requires 3 consecutive qualifying wins with $\ge 90\%$ accuracy at the current level to promote. Two consecutive failures demote by 1 level (bounded to Level 1–10).


