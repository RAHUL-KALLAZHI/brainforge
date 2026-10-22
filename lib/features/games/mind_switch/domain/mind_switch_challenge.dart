import 'package:brainforge/features/games/shared/domain/game_challenge.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// The four distinct multi-sensory color-shape pairs used in Mind Switch.
///
/// Designed to satisfy WCAG high-contrast guidelines and cognitive accessibility:
/// each color is uniquely bound to a tactile geometric shape and semantic label
/// so color-blind players can distinguish options without ambiguity.
enum MindSwitchColor {
  red(
    label: 'Red',
    icon: Icons.diamond_rounded,
    shapeName: 'Diamond',
    darkSurfaceColor: Color(0xFFFF5252),
    lightSurfaceColor: Color(0xFFDC2626),
  ),
  blue(
    label: 'Blue',
    icon: Icons.square_rounded,
    shapeName: 'Square',
    darkSurfaceColor: Color(0xFF60A5FA),
    lightSurfaceColor: Color(0xFF2563EB),
  ),
  green(
    label: 'Green',
    icon: Icons.circle_rounded,
    shapeName: 'Circle',
    darkSurfaceColor: Color(0xFF34D399),
    lightSurfaceColor: Color(0xFF059669),
  ),
  yellow(
    label: 'Yellow',
    icon: Icons.change_history_rounded,
    shapeName: 'Triangle',
    darkSurfaceColor: Color(0xFFFBBF24),
    lightSurfaceColor: Color(0xFFD97706),
  );

  final String label;
  final IconData icon;
  final String shapeName;
  final Color darkSurfaceColor;
  final Color lightSurfaceColor;

  const MindSwitchColor({
    required this.label,
    required this.icon,
    required this.shapeName,
    required this.darkSurfaceColor,
    required this.lightSurfaceColor,
  });

  /// Resolves the accessible surface color according to theme brightness.
  Color resolveColor(Brightness brightness) {
    return brightness == Brightness.dark ? darkSurfaceColor : lightSurfaceColor;
  }

  /// Accessible label combining color name and shape geometry.
  String get semanticLabel => '$label $shapeName';
}

/// The active matching condition for a Mind Switch trial.
enum MindSwitchRule {
  color(
    label: 'Match Ink Color',
    shortLabel: 'INK COLOR',
    instruction: 'Select the color of the ink, ignore what the word says.',
    icon: Icons.palette_rounded,
  ),
  word(
    label: 'Match Word Text',
    shortLabel: 'WORD TEXT',
    instruction: 'Select the color spelled by the word, ignore the ink color.',
    icon: Icons.spellcheck_rounded,
  );

  final String label;
  final String shortLabel;
  final String instruction;
  final IconData icon;

  const MindSwitchRule({
    required this.label,
    required this.shortLabel,
    required this.instruction,
    required this.icon,
  });

  /// Inverts the current rule.
  MindSwitchRule get opposite =>
      this == MindSwitchRule.color ? MindSwitchRule.word : MindSwitchRule.color;
}

/// Immutable data model for a single Mind Switch Stroop trial.
class MindSwitchTrial extends Equatable {
  /// Zero-based index of this trial in the challenge sequence.
  final int index;

  /// The active matching rule for this trial.
  final MindSwitchRule rule;

  /// The semantic color word displayed as text (e.g. "RED").
  final MindSwitchColor wordColor;

  /// The physical font/ink color the text is rendered in.
  final MindSwitchColor inkColor;

  /// Whether this trial represents a rule switch relative to the preceding trial.
  final bool isRuleSwitch;

  const MindSwitchTrial({
    required this.index,
    required this.rule,
    required this.wordColor,
    required this.inkColor,
    required this.isRuleSwitch,
  });

  /// The expected correct answer given the active rule.
  MindSwitchColor get targetColor =>
      rule == MindSwitchRule.color ? inkColor : wordColor;

  /// Whether the word semantics match the ink color (Stroop congruent).
  bool get isCongruent => wordColor == inkColor;

  @override
  List<Object?> get props => [index, rule, wordColor, inkColor, isRuleSwitch];
}

/// Challenge model representing an ordered sequence of Stroop task-switching trials.
class MindSwitchChallenge extends GameChallenge {
  /// The full sequence of trials for this session.
  final List<MindSwitchTrial> trials;

  /// The maximum number of mistakes permitted before the session fails.
  final int maxMistakesAllowed;

  const MindSwitchChallenge({
    required super.roundIndex,
    super.seed,
    required this.trials,
    required this.maxMistakesAllowed,
  });

  /// Total count of trials in this challenge session.
  int get totalTrials => trials.length;

  @override
  List<Object?> get props => [roundIndex, seed, trials, maxMistakesAllowed];
}
