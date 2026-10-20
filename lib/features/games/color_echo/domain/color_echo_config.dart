import 'package:flutter/material.dart';
import '../../shared/domain/game_config.dart';
import '../../shared/domain/game_difficulty.dart';

/// Descriptor for one of the four interactive color pads in Color Echo.
class ColorPadData {
  final int index;
  final String name;
  final Color baseColor;
  final Color activeColor;
  final IconData icon;
  final String semanticLabel;

  const ColorPadData({
    required this.index,
    required this.name,
    required this.baseColor,
    required this.activeColor,
    required this.icon,
    required this.semanticLabel,
  });
}

/// Helper generating validated [GameConfig] presets and pad definitions for Color Echo.
abstract final class ColorEchoConfig {
  static const String gameId = 'color_echo';
  static const String gameTitle = 'Color Echo';

  /// The four distinct color pads.
  static const List<ColorPadData> pads = [
    ColorPadData(
      index: 0,
      name: 'Cyan',
      baseColor: Color(0xFF00838F),
      activeColor: Color(0xFF00E5FF),
      icon: Icons.diamond_rounded,
      semanticLabel: 'Cyan Pad (Diamond, Top Left)',
    ),
    ColorPadData(
      index: 1,
      name: 'Violet',
      baseColor: Color(0xFF4A148C),
      activeColor: Color(0xFFD500F9),
      icon: Icons.circle_rounded,
      semanticLabel: 'Violet Pad (Circle, Top Right)',
    ),
    ColorPadData(
      index: 2,
      name: 'Amber',
      baseColor: Color(0xFFE65100),
      activeColor: Color(0xFFFFAB00),
      icon: Icons.change_history_rounded,
      semanticLabel: 'Amber Pad (Triangle, Bottom Left)',
    ),
    ColorPadData(
      index: 3,
      name: 'Green',
      baseColor: Color(0xFF1B5E20),
      activeColor: Color(0xFF00E676),
      icon: Icons.square_rounded,
      semanticLabel: 'Green Pad (Square, Bottom Right)',
    ),
  ];

  /// Builds a [GameConfig] tailored to the specified [difficulty] level (1 to 10).
  ///
  /// Difficulty scaling:
  /// - Sequence length: 3 at Level 1 up to 12 at Level 10.
  /// - Presentation duration: 800ms down to 350ms.
  /// - Response time limit: 15 seconds.
  /// - Grid: 2 rows x 2 columns (4 pads total).
  /// - Duplicates: allowed (colors can recur multiple times in sequence).
  static GameConfig forDifficulty(
    GameDifficulty difficulty, {
    int? seed,
    Duration? presentationDuration,
    Duration responseTimeLimit = const Duration(seconds: 15),
  }) {
    final int sequenceLength;
    final Duration defaultPresentationDuration;

    switch (difficulty.level) {
      case 1:
        sequenceLength = 3;
        defaultPresentationDuration = const Duration(milliseconds: 800);
        break;
      case 2:
        sequenceLength = 4;
        defaultPresentationDuration = const Duration(milliseconds: 750);
        break;
      case 3:
        sequenceLength = 5;
        defaultPresentationDuration = const Duration(milliseconds: 700);
        break;
      case 4:
        sequenceLength = 6;
        defaultPresentationDuration = const Duration(milliseconds: 650);
        break;
      case 5:
        sequenceLength = 7;
        defaultPresentationDuration = const Duration(milliseconds: 600);
        break;
      case 6:
        sequenceLength = 8;
        defaultPresentationDuration = const Duration(milliseconds: 550);
        break;
      case 7:
        sequenceLength = 9;
        defaultPresentationDuration = const Duration(milliseconds: 500);
        break;
      case 8:
        sequenceLength = 10;
        defaultPresentationDuration = const Duration(milliseconds: 450);
        break;
      case 9:
        sequenceLength = 11;
        defaultPresentationDuration = const Duration(milliseconds: 400);
        break;
      case 10:
      default:
        sequenceLength = 12;
        defaultPresentationDuration = const Duration(milliseconds: 350);
        break;
    }

    final config = GameConfig(
      gameId: gameId,
      difficulty: difficulty,
      gridRows: 2,
      gridColumns: 2,
      sequenceLength: sequenceLength,
      presentationDuration: presentationDuration ?? defaultPresentationDuration,
      responseTimeLimit: responseTimeLimit,
      seed: seed,
      allowDuplicates: true,
    );

    config.validate();
    return config;
  }

  /// Sequence gap duration between illuminated pads during playback.
  static Duration gapDurationForDifficulty(GameDifficulty difficulty) {
    switch (difficulty.level) {
      case 1:
      case 2:
        return const Duration(milliseconds: 200);
      case 3:
      case 4:
        return const Duration(milliseconds: 180);
      case 5:
      case 6:
      case 7:
        return const Duration(milliseconds: 150);
      case 8:
      case 9:
        return const Duration(milliseconds: 120);
      case 10:
      default:
        return const Duration(milliseconds: 100);
    }
  }
}
