import 'package:equatable/equatable.dart';
import 'package:brainforge/features/games/shared/domain/adaptation_action.dart';
import 'package:brainforge/features/games/shared/domain/adaptation_decision.dart';
import 'package:brainforge/features/games/shared/domain/game_config.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import 'package:brainforge/features/games/shared/domain/game_result.dart';
import 'package:brainforge/features/games/shared/domain/game_session_state.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';
import 'package:brainforge/features/games/reverse_recall/domain/reverse_recall_challenge.dart';

/// Immutable state representation for a Reverse Recall gameplay session.
class ReverseRecallState extends Equatable {
  final GameConfig config;
  final ReverseRecallChallenge challenge;
  final GameSessionState sessionState;

  /// Currently flashing digit during the preview playback phase, or null during gaps/input.
  final int? activePresentedDigit;

  /// Index of the digit currently being presented in the forward sequence (0-based).
  final int presentedStepIndex;

  /// 0-based index of the expected reverse digit the player is currently entering.
  final int currentStepIndex;

  /// List of digits entered by the player in reverse order so far.
  final List<int> playerEntries;

  /// Most recently pressed digit on the keypad.
  final int? lastEnteredDigit;

  /// Whether the most recent digit entered was correct.
  final bool? lastInputCorrect;

  /// Whether the exit confirmation dialog is actively visible.
  final bool isExitDialogOpen;

  /// Adaptive difficulty evaluation result computed upon session completion.
  final AdaptationDecision? adaptationDecision;

  const ReverseRecallState({
    required this.config,
    required this.challenge,
    required this.sessionState,
    this.activePresentedDigit,
    this.presentedStepIndex = 0,
    this.currentStepIndex = 0,
    this.playerEntries = const [],
    this.lastEnteredDigit,
    this.lastInputCorrect,
    this.isExitDialogOpen = false,
    this.adaptationDecision,
  });

  /// Factory creating the initial state for Reverse Recall before game launch.
  factory ReverseRecallState.initial({
    required GameConfig config,
    required ReverseRecallChallenge challenge,
    required GameSessionState sessionState,
  }) {
    return ReverseRecallState(
      config: config,
      challenge: challenge,
      sessionState: sessionState,
      activePresentedDigit: null,
      presentedStepIndex: 0,
      currentStepIndex: 0,
      playerEntries: const [],
      lastEnteredDigit: null,
      lastInputCorrect: null,
      isExitDialogOpen: false,
      adaptationDecision: null,
    );
  }

  /// Convenience getters mirroring engine and lifecycle properties.
  GameDifficulty get difficulty => config.difficulty;
  int get targetSequenceLength => challenge.length;
  bool get isTerminal => sessionState.status.isTerminal;
  bool get isPreviewing =>
      sessionState.status == GameStatus.playing &&
      sessionState.phase == GamePhase.preview;
  bool get isInputAllowed =>
      sessionState.status == GameStatus.playing &&
      sessionState.phase == GamePhase.input;
  bool get isCountingDown => sessionState.status == GameStatus.countdown;
  GameResult? get result => sessionState.result;

  /// Difficulty level of the attempt that just resolved.
  GameDifficulty get playedDifficulty => result?.difficulty ?? difficulty;

  /// Whether player performance earned a level increase under adaptive rules.
  bool get canProceedToNextLevel =>
      adaptationDecision?.action == AdaptationAction.promote;

  /// The next target difficulty recommended by the adaptive difficulty service.
  GameDifficulty get recommendedDifficulty =>
      adaptationDecision?.targetDifficulty ?? difficulty;

  /// Fraction of the reverse sequence correctly entered so far (0.0 to 1.0).
  double get progressPercent => targetSequenceLength > 0
      ? (currentStepIndex / targetSequenceLength).clamp(0.0, 1.0)
      : 0.0;

  /// Remaining digits needed to complete the reverse sequence.
  int get remainingItemsCount =>
      (targetSequenceLength - currentStepIndex).clamp(0, targetSequenceLength);

  ReverseRecallState copyWith({
    GameConfig? config,
    ReverseRecallChallenge? challenge,
    GameSessionState? sessionState,
    int? Function()? activePresentedDigit,
    int? presentedStepIndex,
    int? currentStepIndex,
    List<int>? playerEntries,
    int? Function()? lastEnteredDigit,
    bool? Function()? lastInputCorrect,
    bool? isExitDialogOpen,
    AdaptationDecision? Function()? adaptationDecision,
  }) {
    return ReverseRecallState(
      config: config ?? this.config,
      challenge: challenge ?? this.challenge,
      sessionState: sessionState ?? this.sessionState,
      activePresentedDigit: activePresentedDigit != null
          ? activePresentedDigit()
          : this.activePresentedDigit,
      presentedStepIndex: presentedStepIndex ?? this.presentedStepIndex,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      playerEntries: playerEntries ?? this.playerEntries,
      lastEnteredDigit:
          lastEnteredDigit != null ? lastEnteredDigit() : this.lastEnteredDigit,
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
        challenge,
        sessionState,
        activePresentedDigit,
        presentedStepIndex,
        currentStepIndex,
        playerEntries,
        lastEnteredDigit,
        lastInputCorrect,
        isExitDialogOpen,
        adaptationDecision,
      ];
}
