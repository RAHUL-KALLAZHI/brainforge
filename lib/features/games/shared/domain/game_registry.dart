/// Centralized registry defining canonical game identifiers and display name resolution
/// for all BrainForge cognitive training mini-games.
abstract final class GameRegistry {
  /// Canonical game identifiers.
  static const String memoryGrid = 'memory_grid';
  static const String colorEcho = 'color_echo';
  static const String focusHunter = 'focus_hunter';
  static const String vanishingCards = 'vanishing_cards';
  static const String reverseRecall = 'reverse_recall';
  static const String mindSwitch = 'mind_switch';

  static const Map<String, String> _displayNames = {
    memoryGrid: 'Memory Grid',
    colorEcho: 'Color Echo',
    focusHunter: 'Focus Hunter',
    vanishingCards: 'Vanishing Cards',
    reverseRecall: 'Reverse Recall',
    mindSwitch: 'Mind Switch',
  };

  /// Returns the human-readable display name for [gameId].
  ///
  /// For registered game IDs, returns the official title:
  /// - 'memory_grid' -> 'Memory Grid'
  /// - 'color_echo' -> 'Color Echo'
  /// - 'focus_hunter' -> 'Focus Hunter'
  /// - 'vanishing_cards' -> 'Vanishing Cards'
  /// - 'reverse_recall' -> 'Reverse Recall'
  /// - 'mind_switch' -> 'Mind Switch'
  ///
  /// For unknown or unregistered game IDs, safely converts snake_case or
  /// kebab-case strings into Title Case (e.g. 'speed_math' -> 'Speed Math').
  ///
  /// Never defaults to 'Memory Grid' or another specific game for unknown IDs.
  static String getDisplayName(String? gameId) {
    if (gameId == null || gameId.trim().isEmpty) {
      return 'Unknown Game';
    }
    final registered = _displayNames[gameId];
    if (registered != null) {
      return registered;
    }
    return _formatFallbackName(gameId);
  }

  /// Converts arbitrary raw identifiers into readable Title Case words.
  static String _formatFallbackName(String rawId) {
    final parts = rawId.split(RegExp(r'[_\-\s]+'));
    final words = parts
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
        .toList();
    return words.isNotEmpty ? words.join(' ') : 'Unknown Game';
  }
}
