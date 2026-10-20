import 'package:equatable/equatable.dart';
import '../../shared/domain/adaptation_action.dart';
import '../../shared/domain/adaptation_decision.dart';
import '../../shared/domain/game_config.dart';
import '../../shared/domain/game_difficulty.dart';
import '../../shared/domain/game_result.dart';
import '../../shared/domain/game_session_state.dart';
import '../../shared/domain/game_status.dart';
import '../domain/vanishing_cards_config.dart';

/// Presentation and UI state for the Vanishing Cards mini-game.
class VanishingCardsState extends Equatable {
  final GameConfig config;
  final VanishingCardsChallenge challenge;
  final GameSessionState sessionState;
  final bool isPreviewing;
  final int currentTargetStepIndex;
  final Set<int> foundCardPositions;
  final Set<int> mistakePositions;
  final int? lastTappedPosition;
  final bool? lastInputCorrect;
  final AdaptationDecision? adaptationDecision;
  final GameDifficulty? initialHydratedDifficulty;

  const VanishingCardsState({
    required this.config,
    required this.challenge,
    required this.sessionState,
    this.isPreviewing = false,
    this.currentTargetStepIndex = 0,
    this.foundCardPositions = const {},
    this.mistakePositions = const {},
    this.lastTappedPosition,
    this.lastInputCorrect,
    this.adaptationDecision,
    this.initialHydratedDifficulty,
  });

  /// Factory constructor for the initial ready state.
  factory VanishingCardsState.initial({
    required GameConfig config,
    required VanishingCardsChallenge challenge,
    required GameSessionState sessionState,
    GameDifficulty? initialHydratedDifficulty,
  }) {
    return VanishingCardsState(
      config: config,
      challenge: challenge,
      sessionState: sessionState,
      isPreviewing: false,
      currentTargetStepIndex: 0,
      foundCardPositions: const {},
      mistakePositions: const {},
      initialHydratedDifficulty: initialHydratedDifficulty,
    );
  }

  /// Target card currently requested for recall.
  VanishingCard? get currentTargetCard =>
      currentTargetStepIndex < challenge.targetCards.length
          ? challenge.targetCards[currentTargetStepIndex]
          : null;

  /// True when the game is in active recall and accepting card selection.
  bool get isInputAllowed =>
      sessionState.status == GameStatus.playing &&
      sessionState.phase == GamePhase.input &&
      !isPreviewing;

  /// True during 3..2..1 pre-game countdown.
  bool get isCountingDown => sessionState.status == GameStatus.countdown;

  /// True when session has reached a terminal status (completed, failed, abandoned).
  bool get isTerminal => sessionState.status.isTerminal;

  /// True when session is actively playing or previewing.
  bool get isPlaying => sessionState.status == GameStatus.playing;

  /// Total number of target cards to recall in this challenge.
  int get cardsToRecallCount => challenge.targetCards.length;

  /// Alias for cardsToRecallCount.
  int get totalCardsToFind => cardsToRecallCount;

  /// Number of cards successfully recalled so far.
  int get cardsRecalledCount => foundCardPositions.length;

  /// Number of mistakes made so far.
  int get mistakesCount => mistakePositions.length;

  /// Maximum allowed mistakes before failure.
  int get maxErrorsAllowed => challenge.maxErrorsAllowed;

  /// Active difficulty level.
  GameDifficulty get difficulty => config.difficulty;

  /// Difficulty level that was played in this session.
  GameDifficulty get playedDifficulty => config.difficulty;

  /// Resolved game result once terminal.
  GameResult? get result => sessionState.result;

  /// True when player qualified for adaptive promotion.
  bool get canProceedToNextLevel =>
      adaptationDecision != null &&
      adaptationDecision!.action == AdaptationAction.promote &&
      adaptationDecision!.targetDifficulty.level > difficulty.level;

  /// Recommended difficulty level based on adaptive evaluation.
  GameDifficulty get recommendedDifficulty =>
      adaptationDecision?.targetDifficulty ?? difficulty;

  /// All positions on the board that have been tapped.
  Set<int> get selectedPositions =>
      {...foundCardPositions, ...mistakePositions};

  VanishingCardsState copyWith({
    GameConfig? config,
    VanishingCardsChallenge? challenge,
    GameSessionState? sessionState,
    bool? isPreviewing,
    int? currentTargetStepIndex,
    Set<int>? foundCardPositions,
    Set<int>? mistakePositions,
    int? Function()? lastTappedPosition,
    bool? Function()? lastInputCorrect,
    AdaptationDecision? Function()? adaptationDecision,
    GameDifficulty? initialHydratedDifficulty,
  }) {
    return VanishingCardsState(
      config: config ?? this.config,
      challenge: challenge ?? this.challenge,
      sessionState: sessionState ?? this.sessionState,
      isPreviewing: isPreviewing ?? this.isPreviewing,
      currentTargetStepIndex:
          currentTargetStepIndex ?? this.currentTargetStepIndex,
      foundCardPositions: foundCardPositions ?? this.foundCardPositions,
      mistakePositions: mistakePositions ?? this.mistakePositions,
      lastTappedPosition: lastTappedPosition != null
          ? lastTappedPosition()
          : this.lastTappedPosition,
      lastInputCorrect:
          lastInputCorrect != null ? lastInputCorrect() : this.lastInputCorrect,
      adaptationDecision: adaptationDecision != null
          ? adaptationDecision()
          : this.adaptationDecision,
      initialHydratedDifficulty:
          initialHydratedDifficulty ?? this.initialHydratedDifficulty,
    );
  }

  @override
  List<Object?> get props => [
        config,
        challenge,
        sessionState,
        isPreviewing,
        currentTargetStepIndex,
        foundCardPositions,
        mistakePositions,
        lastTappedPosition,
        lastInputCorrect,
        adaptationDecision,
        initialHydratedDifficulty,
      ];
}
