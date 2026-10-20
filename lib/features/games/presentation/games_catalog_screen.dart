import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_keys.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_header.dart';
import '../shared/domain/game_registry.dart';

class _GameInfo {
  final String id;
  final String title;
  final String domain;
  final String description;
  final IconData icon;
  final String phaseAvailability;
  final AppChipColor chipColor;
  final String details;

  const _GameInfo({
    required this.id,
    required this.title,
    required this.domain,
    required this.description,
    required this.icon,
    required this.phaseAvailability,
    required this.chipColor,
    required this.details,
  });
}

/// Catalog of the 6 core cognitive games in BrainForge.
class GamesCatalogScreen extends StatelessWidget {
  const GamesCatalogScreen({super.key});

  static const List<_GameInfo> _games = [
    _GameInfo(
      id: GameRegistry.memoryGrid,
      title: 'Memory Grid',
      domain: 'Visual Memory',
      description:
          'Memorize the illuminated tile sequence and reproduce it in order.',
      icon: Icons.grid_4x4_rounded,
      phaseAvailability: 'Phase 3 MVP',
      chipColor: AppChipColor.violet,
      details:
          'Memory Grid exercises working memory and spatial sequence recall. '
          'Difficulty adapts through grid dimensions (3x3 to 6x6), sequence length, '
          'and display intervals. Available in Phase 3.',
    ),
    _GameInfo(
      id: GameRegistry.focusHunter,
      title: 'Focus Hunter',
      domain: 'Selective Attention',
      description:
          'Quickly locate target symbols amidst increasingly similar distractors.',
      icon: Icons.center_focus_strong_rounded,
      phaseAvailability: 'Phase 6',
      chipColor: AppChipColor.cyan,
      details:
          'Focus Hunter measures selective visual search, inhibition, and response '
          'times under time pressure with target-present and target-absent trials. '
          'Available in Phase 6.',
    ),
    _GameInfo(
      id: GameRegistry.vanishingCards,
      title: 'Vanishing Cards',
      domain: 'Spatial Recall',
      description:
          'Briefly examine revealed cards, then identify target locations once hidden.',
      icon: Icons.style_rounded,
      phaseAvailability: 'Phase 6',
      chipColor: AppChipColor.violet,
      details:
          'Vanishing Cards challenges short-term spatial layout retention and recall '
          'speed under varying exposure windows. Available in Phase 6.',
    ),
    _GameInfo(
      id: GameRegistry.reverseRecall,
      title: 'Reverse Recall',
      domain: 'Working Memory',
      description:
          'Observe alphanumeric or symbol sequences and reproduce them backward.',
      icon: Icons.swap_horiz_rounded,
      phaseAvailability: 'Phase 6',
      chipColor: AppChipColor.cyan,
      details:
          'Reverse Recall requires active mental manipulation and working memory storage '
          'rather than passive rehearsal. Available in Phase 6.',
    ),
    _GameInfo(
      id: GameRegistry.colorEcho,
      title: 'Color Echo',
      domain: 'Audio-Visual Memory',
      description:
          'Follow the multi-sensory color and sound sequence with accessible cues.',
      icon: Icons.music_note_rounded,
      phaseAvailability: 'Playable',
      chipColor: AppChipColor.amber,
      details:
          'Color Echo integrates visual flashes and distinct spatial pads with a 100% accessible '
          'visual fallback. Available now in Phase 6.1.',
    ),
    _GameInfo(
      id: GameRegistry.mindSwitch,
      title: 'Mind Switch',
      domain: 'Cognitive Flexibility',
      description:
          'Adapt to dynamically shifting sorting and matching rules in real-time.',
      icon: Icons.alt_route_rounded,
      phaseAvailability: 'Phase 6',
      chipColor: AppChipColor.violet,
      details:
          'Mind Switch measures task-switching latency, cognitive flexibility, '
          'and error recovery when sorting criteria invert without warning. '
          'Available in Phase 6.',
    ),
  ];

  void _showGameDetails(BuildContext context, _GameInfo game) {
    final theme = Theme.of(context);
    final customTheme = context.brainForgeTheme;
    final router = GoRouter.of(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: customTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
        side: BorderSide(color: Colors.transparent),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: customTheme.accentViolet.withValues(alpha: 0.15),
                        borderRadius: AppSpacing.roundedMd,
                      ),
                      child: Icon(game.icon,
                          color: customTheme.accentViolet, size: 28),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            game.title,
                            style: AppTypography.headlineLarge.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            game.domain,
                            style: AppTypography.bodySmall.copyWith(
                              color: customTheme.accentCyan,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppChip(
                      label: game.phaseAvailability,
                      colorType: game.chipColor,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Overview & Mechanics',
                  style: AppTypography.titleMedium.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  game.details,
                  style: AppTypography.bodyMedium.copyWith(
                    color: customTheme.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  backgroundColor: customTheme.surfaceCardElevated,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.info,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'In Phase 1, games are presented in catalog mode. Active gameplay engines are implemented in Phase 3 & 6.',
                          style: AppTypography.bodySmall.copyWith(
                            color: customTheme.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (game.id == GameRegistry.memoryGrid) ...[
                  AppButton(
                    key: const Key('play_memory_grid_button'),
                    label: 'Play Memory Grid',
                    icon: Icons.play_arrow_rounded,
                    isFullWidth: true,
                    onPressed: () {
                      Navigator.of(context).pop();
                      router.push(AppKeys.memoryGridPath);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (game.id == GameRegistry.colorEcho) ...[
                  AppButton(
                    key: const Key('play_color_echo_button'),
                    label: 'Play Color Echo',
                    icon: Icons.play_arrow_rounded,
                    isFullWidth: true,
                    onPressed: () {
                      Navigator.of(context).pop();
                      router.push(AppKeys.colorEchoPath);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                AppButton(
                  label: 'Close',
                  variant: AppButtonVariant.outline,
                  isFullWidth: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customTheme = context.brainForgeTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.huge),
          children: [
            const AppHeader(
              title: 'Games Catalog',
              subtitle: 'Six Core Cognitive Practice Modes',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: _games.map((game) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppCard(
                      padding: AppSpacing.cardPadding,
                      onTap: () => _showGameDetails(context, game),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: customTheme.accentViolet
                                  .withValues(alpha: 0.15),
                              borderRadius: AppSpacing.roundedMd,
                            ),
                            child: Icon(
                              game.icon,
                              color: customTheme.accentViolet,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        game.title,
                                        style:
                                            AppTypography.titleLarge.copyWith(
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    AppChip(
                                      label: game.phaseAvailability,
                                      colorType: game.chipColor,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  game.domain,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: customTheme.accentCyan,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  game.description,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: customTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
