import 'package:equatable/equatable.dart';
import '../../shared/domain/adaptation_action.dart';
import '../../shared/domain/adaptation_decision.dart';
import '../../shared/domain/game_config.dart';
import '../../shared/domain/game_difficulty.dart';
import '../../shared/domain/game_result.dart';
import '../../shared/domain/game_session_state.dart';
import '../../shared/domain/game_status.dart';
import '../domain/focus_hunter_config.dart';

/// Presentation and lifecycle state for a Focus Hunter session.
class FocusHunterState extends Equatable {
  final GameConfig config;
  final GameSessionState sessionState;
  final FocusHunterChallenge challenge;
  final Set<int> foundTargetIndices;
  final Set<int> mistakeIndices;
  final int? lastTappedIndex;
  final bool? lastInputCorrect;
  final bool isExitDialogOpen;
  final AdaptationDecision? adaptationDecision;

  const FocusHunterState({
    required this.config,
    required this.sessionState,
    required this.challenge,
    this.foundTargetIndices = const {},
    this.mistakeIndices = const {},
    this.lastTappedIndex,
    this.lastInputCorrect,
    this.isExitDialogOpen = false,
    this.adaptationDecision,
  });

  /// Factory creating initial state for Focus Hunter.
  factory FocusHunterState.initial({
    required GameConfig config,
    required FocusHunterChallenge challenge,
    required GameSessionState sessionState,
  }) {
    return FocusHunterState(
      config: config,
      challenge: challenge,
      sessionState: sessionState,
      foundTargetIndices: const {},
      mistakeIndices: const {},
      lastTappedIndex: null,
      lastInputCorrect: null,
      isExitDialogOpen: false,
    );
  }

  /// Combined set of all selected items (prevents duplicate taps).
  Set<int> get selectedIndices => {...foundTargetIndices, ...mistakeIndices};

  /// Whether player touch input on grid items is currently permitted.
  bool get isInputAllowed =>
      sessionState.status == GameStatus.playing &&
      sessionState.phase == GamePhase.input;

  /// Whether the session is in the pre-game countdown (3, 2, 1).
  bool get isCountingDown => sessionState.status == GameStatus.countdown;

  /// Whether the session is actively playing or paused.
  bool get isActive =>
      sessionState.status == GameStatus.playing ||
      sessionState.status == GameStatus.paused;

  /// Whether the session has concluded in a terminal outcome.
  bool get isTerminal => sessionState.status.isTerminal;

  /// Total targets required to find.
  int get targetCount => challenge.targetCount;

  /// Total targets successfully found so far.
  int get targetsFound => foundTargetIndices.length;

  /// Remaining targets to find.
  int get targetsRemaining => challenge.targetCount - foundTargetIndices.length;

  /// Total mistakes made so far.
  int get mistakesCount => mistakeIndices.length;

  /// Maximum mistakes allowed before failure.
  int get maxErrorsAllowed => challenge.maxErrorsAllowed;

  /// Current difficulty level.
  GameDifficulty get difficulty => config.difficulty;

  /// The difficulty level of the session that was actually played.
  GameDifficulty get playedDifficulty =>
      sessionState.result?.difficulty ?? config.difficulty;

  /// The recommended difficulty from adaptation (or played difficulty if no adaptation).
  GameDifficulty get recommendedDifficulty =>
      adaptationDecision?.targetDifficulty ?? playedDifficulty;

  /// Whether a valid promotion is available allowing progression to next level.
  bool get canProceedToNextLevel =>
      adaptationDecision != null &&
      adaptationDecision!.action == AdaptationAction.promote &&
      adaptationDecision!.targetDifficulty.level > playedDifficulty.level &&
      playedDifficulty.level < GameDifficulty.maxLevel;

  /// Number of consecutive qualifying wins achieved at the current played difficulty.
  int get qualifyingWinsCount => adaptationDecision?.qualifyingWinsCount ?? 0;

  /// Completed result if session reached a terminal state.
  GameResult? get result => sessionState.result;

  FocusHunterState copyWith({
    GameConfig? config,
    GameSessionState? sessionState,
    FocusHunterChallenge? challenge,
    Set<int>? foundTargetIndices,
    Set<int>? mistakeIndices,
    int? Function()? lastTappedIndex,
    bool? Function()? lastInputCorrect,
    bool? isExitDialogOpen,
    AdaptationDecision? Function()? adaptationDecision,
  }) {
    return FocusHunterState(
      config: config ?? this.config,
      sessionState: sessionState ?? this.sessionState,
      challenge: challenge ?? this.challenge,
      foundTargetIndices: foundTargetIndices ?? this.foundTargetIndices,
      mistakeIndices: mistakeIndices ?? this.mistakeIndices,
      lastTappedIndex:
          lastTappedIndex != null ? lastTappedIndex() : this.lastTappedIndex,
      lastInputCorrect:
          lastInputCorrect != null ? lastInputCorrect() : this.lastInputCorrect,
      isExitDialogOpen: isExitDialogOpen ?? this.isExitDialogOpen,
      adaptationDecision: adaptationDecision != null
          ? adaptationDecision()
          : this.adaptationDecision,
    );
  }

  @override
  List<Object?> get props => [
        config,
        sessionState,
        challenge,
        foundTargetIndices,
        mistakeIndices,
        lastTappedIndex,
        lastInputCorrect,
        isExitDialogOpen,
        adaptationDecision,
      ];
}
