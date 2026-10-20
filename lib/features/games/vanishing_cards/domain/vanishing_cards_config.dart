import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../shared/domain/game_challenge.dart';
import '../../shared/domain/game_config.dart';
import '../../shared/domain/game_difficulty.dart';

/// Distinct recognizable card symbols used across Vanishing Cards layouts.
enum VanishingCardSymbol {
  crown(Icons.workspace_premium_rounded, 'Crown', 'Golden crown symbol'),
  anchor(Icons.anchor_rounded, 'Anchor', 'Maritime anchor symbol'),
  key(Icons.vpn_key_rounded, 'Key', 'Antique key symbol'),
  compass(Icons.explore_rounded, 'Compass', 'Navigational compass symbol'),
  bell(Icons.notifications_rounded, 'Bell', 'Ringing bell symbol'),
  feather(Icons.draw_rounded, 'Feather', 'Quill feather symbol'),
  hourglass(
      Icons.hourglass_bottom_rounded, 'Hourglass', 'Time hourglass symbol'),
  lantern(Icons.lightbulb_rounded, 'Lantern', 'Glowing lantern symbol'),
  shield(Icons.shield_rounded, 'Shield', 'Protective crest symbol'),
  diamond(Icons.diamond_rounded, 'Diamond', 'Precious diamond gem'),
  star(Icons.star_rounded, 'Star', 'Five-point star symbol'),
  heart(Icons.favorite_rounded, 'Heart', 'Classic heart symbol'),
  bolt(Icons.bolt_rounded, 'Bolt', 'Lightning bolt symbol'),
  moon(Icons.nightlight_round, 'Moon', 'Crescent moon symbol'),
  sun(Icons.wb_sunny_rounded, 'Sun', 'Radiant sun symbol'),
  flame(Icons.local_fire_department_rounded, 'Flame', 'Blazing fire symbol');

  final IconData icon;
  final String label;
  final String semanticDescription;

  const VanishingCardSymbol(this.icon, this.label, this.semanticDescription);
}

/// An individual card placed on the board with its unique symbol and position index.
class VanishingCard extends Equatable {
  final int id;
  final VanishingCardSymbol symbol;
  final int positionIndex;

  const VanishingCard({
    required this.id,
    required this.symbol,
    required this.positionIndex,
  });

  @override
  List<Object?> get props => [id, symbol, positionIndex];
}

/// Challenge data model containing the board cards and target cards to locate.
class VanishingCardsChallenge extends GameChallenge {
  final List<VanishingCard> cards;
  final List<VanishingCard> targetCards;
  final int gridRows;
  final int gridColumns;
  final Duration previewDuration;
  final int maxErrorsAllowed;

  const VanishingCardsChallenge({
    required super.roundIndex,
    super.seed,
    required this.cards,
    required this.targetCards,
    required this.gridRows,
    required this.gridColumns,
    required this.previewDuration,
    required this.maxErrorsAllowed,
  });

  /// Set of 0-based position indices for the requested target cards.
  Set<int> get targetPositions =>
      {for (final t in targetCards) t.positionIndex};

  @override
  List<Object?> get props => [
        roundIndex,
        seed,
        cards,
        targetCards,
        gridRows,
        gridColumns,
        previewDuration,
        maxErrorsAllowed,
      ];
}

/// Central configuration helper defining presets and difficulty mappings for Vanishing Cards.
abstract final class VanishingCardsConfig {
  static const String gameId = 'vanishing_cards';
  static const String gameTitle = 'Vanishing Cards';

  /// Maximum allowed errors before session failure for a given [difficulty].
  static int maxErrorsForDifficulty(GameDifficulty difficulty) {
    switch (difficulty.level) {
      case 1:
      case 2:
      case 3:
      case 4:
        return 2;
      case 5:
      case 6:
      case 7:
      case 8:
        return 1;
      case 9:
      case 10:
      default:
        return 0;
    }
  }

  /// Preview exposure duration for a given [difficulty].
  static Duration previewDurationForDifficulty(GameDifficulty difficulty) {
    switch (difficulty.level) {
      case 1:
        return const Duration(milliseconds: 4000);
      case 2:
      case 3:
        return const Duration(milliseconds: 3500);
      case 4:
      case 5:
        return const Duration(milliseconds: 3000);
      case 6:
      case 7:
        return const Duration(milliseconds: 2500);
      case 8:
      case 9:
        return const Duration(milliseconds: 2000);
      case 10:
      default:
        return const Duration(milliseconds: 1500);
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
        targetCount = 2;
        defaultTimeLimit = const Duration(seconds: 15);
        break;
      case 2:
        rows = 3;
        columns = 3;
        targetCount = 3;
        defaultTimeLimit = const Duration(seconds: 15);
        break;
      case 3:
        rows = 3;
        columns = 3;
        targetCount = 4;
        defaultTimeLimit = const Duration(seconds: 14);
        break;
      case 4:
        rows = 4;
        columns = 3;
        targetCount = 4;
        defaultTimeLimit = const Duration(seconds: 14);
        break;
      case 5:
        rows = 4;
        columns = 3;
        targetCount = 5;
        defaultTimeLimit = const Duration(seconds: 13);
        break;
      case 6:
        rows = 4;
        columns = 3;
        targetCount = 6;
        defaultTimeLimit = const Duration(seconds: 13);
        break;
      case 7:
        rows = 4;
        columns = 4;
        targetCount = 6;
        defaultTimeLimit = const Duration(seconds: 12);
        break;
      case 8:
        rows = 4;
        columns = 4;
        targetCount = 7;
        defaultTimeLimit = const Duration(seconds: 12);
        break;
      case 9:
        rows = 4;
        columns = 4;
        targetCount = 8;
        defaultTimeLimit = const Duration(seconds: 10);
        break;
      case 10:
      default:
        rows = 4;
        columns = 4;
        targetCount = 9;
        defaultTimeLimit = const Duration(seconds: 10);
        break;
    }

    final totalCards = rows * columns;
    final distractorCount = totalCards - targetCount;

    final config = GameConfig(
      gameId: gameId,
      difficulty: difficulty,
      gridRows: rows,
      gridColumns: columns,
      sequenceLength: targetCount,
      presentationDuration: previewDurationForDifficulty(difficulty),
      responseTimeLimit: responseTimeLimit ?? defaultTimeLimit,
      distractorCount: distractorCount,
      targetRounds: 1,
      seed: seed,
      allowDuplicates: false,
    );

    config.validate();
    return config;
  }
}
