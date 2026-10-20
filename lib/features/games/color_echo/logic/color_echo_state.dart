import 'package:equatable/equatable.dart';
import '../../shared/domain/adaptation_action.dart';
import '../../shared/domain/adaptation_decision.dart';
import '../../shared/domain/game_config.dart';
import '../../shared/domain/game_difficulty.dart';
import '../../shared/domain/game_result.dart';
import '../../shared/domain/game_session_state.dart';
import '../../shared/domain/game_status.dart';
import '../../shared/logic/challenge_generator.dart';

/// Immutable presentation and lifecycle state for a Color Echo session.
class ColorEchoState extends Equatable {
  final GameConfig config;
  final GameSessionState sessionState;
  final SequenceChallenge challenge;
  final int? activePreviewPadIndex;
  final int currentStepIndex;
  final List<int> playerSelections;
  final int? lastTappedPad;
  final bool? lastInputCorrect;
  final bool isExitDialogOpen;
  final AdaptationDecision? adaptationDecision;

  const ColorEchoState({
    required this.config,
    required this.sessionState,
    required this.challenge,
    this.activePreviewPadIndex,
    this.currentStepIndex = 0,
    this.playerSelections = const [],
    this.lastTappedPad,
    this.lastInputCorrect,
    this.isExitDialogOpen = false,
    this.adaptationDecision,
  });

  /// Factory creating the initial state for Color Echo.
  factory ColorEchoState.initial({
    required GameConfig config,
    required SequenceChallenge challenge,
    required GameSessionState sessionState,
  }) {
    return ColorEchoState(
      config: config,
      challenge: challenge,
      sessionState: sessionState,
      activePreviewPadIndex: null,
      currentStepIndex: 0,
      playerSelections: const [],
      lastTappedPad: null,
      lastInputCorrect: null,
      isExitDialogOpen: false,
    );
  }

  /// Whether player touch input on color pads is currently permitted.
  bool get isInputAllowed =>
      sessionState.status == GameStatus.playing &&
      sessionState.phase == GamePhase.input;

  /// Whether sequence playback is actively illuminating color pads.
  bool get isPreviewing =>
      sessionState.status == GameStatus.playing &&
      sessionState.phase == GamePhase.preview;

  /// Whether the session is in the pre-game countdown (3, 2, 1).
  bool get isCountingDown => sessionState.status == GameStatus.countdown;

  /// Whether the session is actively playing or paused.
  bool get isActive =>
      sessionState.status == GameStatus.playing ||
      sessionState.status == GameStatus.paused;

  /// Whether the session has concluded in a terminal outcome.
  bool get isTerminal => sessionState.status.isTerminal;

  /// Target sequence length to memorize and reproduce.
  int get targetSequenceLength => challenge.sequence.length;

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

  ColorEchoState copyWith({
    GameConfig? config,
    GameSessionState? sessionState,
    SequenceChallenge? challenge,
    int? Function()? activePreviewPadIndex,
    int? currentStepIndex,
    List<int>? playerSelections,
    int? Function()? lastTappedPad,
    bool? Function()? lastInputCorrect,
    bool? isExitDialogOpen,
    AdaptationDecision? Function()? adaptationDecision,
  }) {
    return ColorEchoState(
      config: config ?? this.config,
      sessionState: sessionState ?? this.sessionState,
      challenge: challenge ?? this.challenge,
      activePreviewPadIndex: activePreviewPadIndex != null
          ? activePreviewPadIndex()
          : this.activePreviewPadIndex,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      playerSelections: playerSelections ?? this.playerSelections,
      lastTappedPad:
          lastTappedPad != null ? lastTappedPad() : this.lastTappedPad,
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
        activePreviewPadIndex,
        currentStepIndex,
        playerSelections,
        lastTappedPad,
        lastInputCorrect,
        isExitDialogOpen,
        adaptationDecision,
      ];
}
