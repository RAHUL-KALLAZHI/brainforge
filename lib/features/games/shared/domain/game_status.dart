/// Core lifecycle statuses for any game session in BrainForge.
enum GameStatus {
  /// Session has been created with a configuration, but not yet started.
  initial,

  /// Instructions or tutorial modal is currently displayed to the player.
  instructions,

  /// Active pre-game countdown (e.g. 3..2..1..Go).
  countdown,

  /// Active gameplay session in progress (presenting challenge or awaiting input).
  playing,

  /// Gameplay has been temporarily suspended by the player or lifecycle pause.
  paused,

  /// Game has been successfully completed and objectives met.
  completed,

  /// Game terminated due to timeout or maximum mistake limit reached.
  failed,

  /// Player exited, navigated away, or explicitly quit the session prematurely.
  abandoned;

  /// True if the game is in a final, immutable terminal state.
  bool get isTerminal =>
      this == GameStatus.completed ||
      this == GameStatus.failed ||
      this == GameStatus.abandoned;

  /// True if the game is actively running and consuming clock cycles.
  bool get isActive =>
      this == GameStatus.countdown ||
      this == GameStatus.playing ||
      this == GameStatus.paused;

  /// True if the game can currently accept player interactions.
  bool get canAcceptInput => this == GameStatus.playing;
}

/// Phases within an active [GameStatus.playing] state.
enum GamePhase {
  /// Challenge is currently being displayed (e.g. lighting up sequence); input locked.
  preview,

  /// Challenge is hidden and the game is actively awaiting player response.
  input,

  /// Brief visual/auditory feedback for a single round submission.
  roundFeedback,

  /// Intermission delay between consecutive rounds.
  intermission;

  /// Whether user touch/keyboard input is allowed during this phase.
  bool get isInputAllowed => this == GamePhase.input;
}
