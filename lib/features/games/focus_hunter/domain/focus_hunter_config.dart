import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../shared/domain/game_challenge.dart';
import '../../shared/domain/game_config.dart';
import '../../shared/domain/game_difficulty.dart';

/// Distinct visual geometric symbols used in Focus Hunter.
enum FocusSymbolType {
  star(Icons.star_rounded, 'Star', 'star symbol'),
  hexagon(Icons.hexagon_rounded, 'Hexagon', 'six-sided hexagon'),
  diamond(Icons.diamond_rounded, 'Diamond', 'faceted diamond'),
  circle(Icons.circle_rounded, 'Circle', 'solid circle'),
  square(Icons.square_rounded, 'Square', 'rounded square'),
  triangle(Icons.change_history_rounded, 'Triangle', 'three-sided triangle'),
  shield(Icons.shield_rounded, 'Shield', 'protective shield'),
  bolt(Icons.bolt_rounded, 'Bolt', 'lightning bolt');

  final IconData icon;
  final String label;
  final String semanticDescription;

  const FocusSymbolType(this.icon, this.label, this.semanticDescription);
}

/// Curated high-contrast color palette accessible on both dark and light surfaces.
enum FocusColorType {
  cyan(
    Color(0xFF00E5FF),
    Color(0xFF00838F),
    'Cyan',
  ),
  violet(
    Color(0xFFD500F9),
    Color(0xFF4A148C),
    'Violet',
  ),
  amber(
    Color(0xFFFFAB00),
    Color(0xFFE65100),
    'Amber',
  ),
  emerald(
    Color(0xFF00E676),
    Color(0xFF1B5E20),
    'Emerald',
  ),
  coral(
    Color(0xFFFF5252),
    Color(0xFFC62828),
    'Coral',
  ),
  blue(
    Color(0xFF448AFF),
    Color(0xFF1565C0),
    'Blue',
  );

  final Color lightSurfaceColor;
  final Color darkSurfaceColor;
  final String label;

  const FocusColorType(
    this.lightSurfaceColor,
    this.darkSurfaceColor,
    this.label,
  );

  /// Resolves the vibrant accent color based on active theme brightness.
  Color resolveColor(Brightness brightness) {
    return brightness == Brightness.dark ? lightSurfaceColor : darkSurfaceColor;
  }
}

/// Immutable data model for an individual item displayed on the Focus Hunter grid.
class FocusHunterItem extends Equatable {
  final int id;
  final FocusSymbolType symbol;
  final FocusColorType color;
  final bool isTarget;

  const FocusHunterItem({
    required this.id,
    required this.symbol,
    required this.color,
    required this.isTarget,
  });

  @override
  List<Object?> get props => [id, symbol, color, isTarget];
}

/// Challenge model representing a generated Focus Hunter board.
class FocusHunterChallenge extends GameChallenge {
  final FocusSymbolType targetSymbol;
  final FocusColorType targetColor;
  final List<FocusHunterItem> items;
  final int targetCount;
  final int gridRows;
  final int gridColumns;
  final int maxErrorsAllowed;

  const FocusHunterChallenge({
    required super.roundIndex,
    super.seed,
    required this.targetSymbol,
    required this.targetColor,
    required this.items,
    required this.targetCount,
    required this.gridRows,
    required this.gridColumns,
    required this.maxErrorsAllowed,
  });

  /// Set of 0-based indices corresponding to target items in [items].
  Set<int> get targetIndices => {
        for (int i = 0; i < items.length; i++)
          if (items[i].isTarget) i,
      };

  @override
  List<Object?> get props => [
        roundIndex,
        seed,
        targetSymbol,
        targetColor,
        items,
        targetCount,
        gridRows,
        gridColumns,
        maxErrorsAllowed,
      ];
}

/// Helper generating validated [GameConfig] presets and parameters for Focus Hunter.
abstract final class FocusHunterConfig {
  static const String gameId = 'focus_hunter';
  static const String gameTitle = 'Focus Hunter';

  /// Maximum allowed errors before session failure for a given [difficulty].
  static int maxErrorsForDifficulty(GameDifficulty difficulty) {
    switch (difficulty.level) {
      case 1:
      case 2:
      case 3:
      case 4:
        return 3;
      case 5:
      case 6:
      case 7:
      case 8:
        return 2;
      case 9:
      case 10:
      default:
        return 1;
    }
  }

  /// Builds a validated [GameConfig] tailored to the specified [difficulty] level (1 to 10).
  static GameConfig forDifficulty(
    GameDifficulty difficulty, {
    int? seed,
    Duration? responseTimeLimit,
  }) {
    final int rows;
    final int columns;
    final int targetCount;
    final Duration defaultTimeLimit;

    switch (difficulty.level) {
      case 1:
        rows = 3;
        columns = 3;
        targetCount = 1;
        defaultTimeLimit = const Duration(seconds: 15);
        break;
      case 2:
        rows = 3;
        columns = 3;
        targetCount = 2;
        defaultTimeLimit = const Duration(seconds: 15);
        break;
      case 3:
        rows = 4;
        columns = 3;
        targetCount = 2;
        defaultTimeLimit = const Duration(seconds: 14);
        break;
      case 4:
        rows = 4;
        columns = 4;
        targetCount = 3;
        defaultTimeLimit = const Duration(seconds: 13);
        break;
      case 5:
        rows = 4;
        columns = 4;
        targetCount = 3;
        defaultTimeLimit = const Duration(seconds: 12);
        break;
      case 6:
        rows = 5;
        columns = 4;
        targetCount = 4;
        defaultTimeLimit = const Duration(seconds: 12);
        break;
      case 7:
        rows = 5;
        columns = 4;
        targetCount = 4;
        defaultTimeLimit = const Duration(seconds: 10);
        break;
      case 8:
        rows = 5;
        columns = 5;
        targetCount = 5;
        defaultTimeLimit = const Duration(seconds: 10);
        break;
      case 9:
        rows = 5;
        columns = 5;
        targetCount = 5;
        defaultTimeLimit = const Duration(seconds: 9);
        break;
      case 10:
      default:
        rows = 6;
        columns = 5;
        targetCount = 6;
        defaultTimeLimit = const Duration(seconds: 8);
        break;
    }

    final totalTiles = rows * columns;
    final distractorCount = totalTiles - targetCount;

    final config = GameConfig(
      gameId: gameId,
      difficulty: difficulty,
      gridRows: rows,
      gridColumns: columns,
      sequenceLength: targetCount,
      presentationDuration: const Duration(milliseconds: 500),
      responseTimeLimit: responseTimeLimit ?? defaultTimeLimit,
      distractorCount: distractorCount,
      targetRounds: 1,
      seed: seed,
      allowDuplicates: true,
    );

    config.validate();
    return config;
  }
}
