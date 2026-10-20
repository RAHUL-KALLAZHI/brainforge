import 'package:equatable/equatable.dart';
import '../../shared/domain/adaptation_action.dart';
import '../../shared/domain/adaptation_decision.dart';
import '../../shared/domain/game_config.dart';
import '../../shared/domain/game_difficulty.dart';
import '../../shared/domain/game_result.dart';
import '../../shared/domain/game_session_state.dart';
import '../../shared/domain/game_status.dart';
import '../../shared/logic/challenge_generator.dart';

/// Immutable presentation and lifecycle state for a Memory Grid session.
class MemoryGridState extends Equatable {
  final GameConfig config;
  final GameSessionState sessionState;
  final SequenceChallenge challenge;
  final int? activePreviewTileIndex;
  final int currentStepIndex;
  final List<int> playerSelections;
  final int? lastTappedTile;
  final bool? lastInputCorrect;
  final bool isExitDialogOpen;
  final AdaptationDecision? adaptationDecision;

  const MemoryGridState({
    required this.config,
    required this.sessionState,
    required this.challenge,
    this.activePreviewTileIndex,
    this.currentStepIndex = 0,
    this.playerSelections = const [],
    this.lastTappedTile,
    this.lastInputCorrect,
    this.isExitDialogOpen = false,
    this.adaptationDecision,
  });

  /// Factory creating the initial state for Memory Grid.
  factory MemoryGridState.initial({
    required GameConfig config,
    required SequenceChallenge challenge,
    required GameSessionState sessionState,
  }) {
    return MemoryGridState(
      config: config,
      challenge: challenge,
      sessionState: sessionState,
      activePreviewTileIndex: null,
      currentStepIndex: 0,
      playerSelections: const [],
      lastTappedTile: null,
      lastInputCorrect: null,
      isExitDialogOpen: false,
    );
  }

  /// Whether player touch input on grid tiles is currently permitted.
  bool get isInputAllowed =>
      sessionState.status == GameStatus.playing &&
      sessionState.phase == GamePhase.input;

  /// Whether sequence preview is actively illuminating tiles.
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

  /// Total number of tiles on the grid (rows * columns).
  int get totalTiles => (config.gridRows ?? 3) * (config.gridColumns ?? 3);

  /// Target sequence length to memorize.
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

  MemoryGridState copyWith({
    GameConfig? config,
    GameSessionState? sessionState,
    SequenceChallenge? challenge,
    int? Function()? activePreviewTileIndex,
    int? currentStepIndex,
    List<int>? playerSelections,
    int? Function()? lastTappedTile,
    bool? Function()? lastInputCorrect,
    bool? isExitDialogOpen,
    AdaptationDecision? Function()? adaptationDecision,
  }) {
    return MemoryGridState(
      config: config ?? this.config,
      sessionState: sessionState ?? this.sessionState,
      challenge: challenge ?? this.challenge,
      activePreviewTileIndex: activePreviewTileIndex != null
          ? activePreviewTileIndex()
          : this.activePreviewTileIndex,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      playerSelections: playerSelections ?? this.playerSelections,
      lastTappedTile:
          lastTappedTile != null ? lastTappedTile() : this.lastTappedTile,
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
        activePreviewTileIndex,
        currentStepIndex,
        playerSelections,
        lastTappedTile,
        lastInputCorrect,
        isExitDialogOpen,
        adaptationDecision,
      ];
}
