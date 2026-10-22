import 'package:equatable/equatable.dart';
import 'package:brainforge/features/games/shared/domain/adaptation_action.dart';
import 'package:brainforge/features/games/shared/domain/adaptation_decision.dart';
import 'package:brainforge/features/games/shared/domain/game_config.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import 'package:brainforge/features/games/shared/domain/game_result.dart';
import 'package:brainforge/features/games/shared/domain/game_session_state.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';
import 'package:brainforge/features/games/mind_switch/domain/mind_switch_challenge.dart';

/// Immutable state representation for a Mind Switch gameplay session.
class MindSwitchState extends Equatable {
  final GameConfig config;
  final MindSwitchChallenge challenge;
  final GameSessionState sessionState;

  /// 0-based index of the currently active trial.
  final int currentTrialIndex;

  /// Most recently selected color option.
  final MindSwitchColor? lastSelectedColor;

  /// Whether the most recent choice was correct.
  final bool? lastInputCorrect;

  /// Number of incorrect responses or trial timeouts so far.
  final int mistakeCount;

  /// Number of correct responses so far.
  final int correctCount;

  /// Remaining duration for the active trial countdown.
  final Duration trialTimeRemaining;

  /// Allocated total duration for each trial at this difficulty.
  final Duration trialTimeLimit;

  /// Whether the "RULE SWITCH!" animated alert is currently showing.
  final bool showRuleSwitchBanner;

  /// Whether the exit confirmation dialog is actively visible.
  final bool isExitDialogOpen;

  /// Adaptive difficulty evaluation result computed upon session completion.
  final AdaptationDecision? adaptationDecision;

  const MindSwitchState({
    required this.config,
    required this.challenge,
    required this.sessionState,
    this.currentTrialIndex = 0,
    this.lastSelectedColor,
    this.lastInputCorrect,
    this.mistakeCount = 0,
    this.correctCount = 0,
    this.trialTimeRemaining = Duration.zero,
    this.trialTimeLimit = Duration.zero,
    this.showRuleSwitchBanner = false,
    this.isExitDialogOpen = false,
    this.adaptationDecision,
  });

  /// Factory creating the initial state for Mind Switch before game launch.
  factory MindSwitchState.initial({
    required GameConfig config,
    required MindSwitchChallenge challenge,
    required GameSessionState sessionState,
  }) {
    final limit = config.responseTimeLimit ?? const Duration(seconds: 5);
    return MindSwitchState(
      config: config,
      challenge: challenge,
      sessionState: sessionState,
      currentTrialIndex: 0,
      lastSelectedColor: null,
      lastInputCorrect: null,
      mistakeCount: 0,
      correctCount: 0,
      trialTimeRemaining: limit,
      trialTimeLimit: limit,
      showRuleSwitchBanner: false,
      isExitDialogOpen: false,
      adaptationDecision: null,
    );
  }

  /// Active trial data, or null if beyond total challenge length.
  MindSwitchTrial? get currentTrial =>
      currentTrialIndex < challenge.trials.length
          ? challenge.trials[currentTrialIndex]
          : null;

  /// Active matching rule for the current trial.
  MindSwitchRule get currentRule =>
      currentTrial?.rule ??
      (challenge.trials.isNotEmpty
          ? challenge.trials.first.rule
          : MindSwitchRule.color);

  /// Target color expected for the active trial.
  MindSwitchColor? get targetColor => currentTrial?.targetColor;

  /// Convenience getters mirroring engine and lifecycle properties.
  GameDifficulty get difficulty => config.difficulty;
  int get totalTrials => challenge.totalTrials;
  bool get isTerminal => sessionState.status.isTerminal;
  bool get isPlaying => sessionState.status == GameStatus.playing;
  bool get isCountingDown => sessionState.status == GameStatus.countdown;
  bool get isInputAllowed => isPlaying && !showRuleSwitchBanner && !isTerminal;
  GameResult? get result => sessionState.result;

  /// Difficulty level of the attempt that just resolved.
  GameDifficulty get playedDifficulty => result?.difficulty ?? difficulty;

  /// Whether player performance earned a level increase under adaptive rules.
  bool get canProceedToNextLevel =>
      adaptationDecision?.action == AdaptationAction.promote;

  /// The next target difficulty recommended by the adaptive difficulty service.
  GameDifficulty get recommendedDifficulty =>
      adaptationDecision?.targetDifficulty ?? difficulty;

  /// Progress through total trials (0.0 to 1.0).
  double get progressFraction =>
      totalTrials > 0 ? (currentTrialIndex / totalTrials).clamp(0.0, 1.0) : 0.0;

  /// Number of mistakes remaining before session failure.
  int get mistakesRemaining => (challenge.maxMistakesAllowed - mistakeCount)
      .clamp(0, challenge.maxMistakesAllowed);

  MindSwitchState copyWith({
    GameConfig? config,
    MindSwitchChallenge? challenge,
    GameSessionState? sessionState,
    int? currentTrialIndex,
    MindSwitchColor? Function()? lastSelectedColor,
    bool? Function()? lastInputCorrect,
    int? mistakeCount,
    int? correctCount,
    Duration? trialTimeRemaining,
    Duration? trialTimeLimit,
    bool? showRuleSwitchBanner,
    bool? isExitDialogOpen,
    AdaptationDecision? Function()? adaptationDecision,
  }) {
    return MindSwitchState(
      config: config ?? this.config,
      challenge: challenge ?? this.challenge,
      sessionState: sessionState ?? this.sessionState,
      currentTrialIndex: currentTrialIndex ?? this.currentTrialIndex,
      lastSelectedColor: lastSelectedColor != null
          ? lastSelectedColor()
          : this.lastSelectedColor,
      lastInputCorrect:
          lastInputCorrect != null ? lastInputCorrect() : this.lastInputCorrect,
      mistakeCount: mistakeCount ?? this.mistakeCount,
      correctCount: correctCount ?? this.correctCount,
      trialTimeRemaining: trialTimeRemaining ?? this.trialTimeRemaining,
      trialTimeLimit: trialTimeLimit ?? this.trialTimeLimit,
      showRuleSwitchBanner: showRuleSwitchBanner ?? this.showRuleSwitchBanner,
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
        currentTrialIndex,
        lastSelectedColor,
        lastInputCorrect,
        mistakeCount,
        correctCount,
        trialTimeRemaining,
        trialTimeLimit,
        showRuleSwitchBanner,
        isExitDialogOpen,
        adaptationDecision,
      ];
}
