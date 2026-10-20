import 'package:flutter/material.dart';
import 'package:brainforge/core/constants/app_spacing.dart';
import 'package:brainforge/core/constants/app_typography.dart';
import 'package:brainforge/core/theme/theme_extensions.dart';
import 'package:brainforge/core/widgets/app_button.dart';
import 'package:brainforge/core/widgets/app_card.dart';
import 'package:brainforge/core/widgets/app_chip.dart';
import 'package:brainforge/features/games/focus_hunter/domain/focus_hunter_config.dart';
import 'package:brainforge/features/games/focus_hunter/logic/focus_hunter_state.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';

/// Introduction and difficulty setup screen for Focus Hunter.
class FocusHunterReadyView extends StatelessWidget {
  final FocusHunterState state;
  final ValueChanged<GameDifficulty> onDifficultyChanged;
  final VoidCallback onStartPressed;
  final VoidCallback onExitPressed;

  const FocusHunterReadyView({
    super.key,
    required this.state,
    required this.onDifficultyChanged,
    required this.onStartPressed,
    required this.onExitPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customTheme = context.brainForgeTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xxl,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Navigation Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    key: const Key('focus_hunter_ready_back_button'),
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: onExitPressed,
                    tooltip: 'Back to Games',
                  ),
                  const Flexible(
                    child: AppChip(
                      label: 'Selective Attention',
                      colorType: AppChipColor.cyan,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Title Icon & Header
              Center(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: customTheme.accentCyan.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.center_focus_strong_rounded,
                    color: customTheme.accentCyan,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Focus Hunter',
                textAlign: TextAlign.center,
                style: AppTypography.displayMedium.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Scan the grid to spot and tap all specified target items while resisting visual distractors.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: customTheme.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Visual Differentiation Sample Preview
              Center(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildPreviewBadge(
                      context,
                      icon: FocusSymbolType.diamond.icon,
                      color: FocusColorType.cyan.resolveColor(theme.brightness),
                      label: 'Diamond',
                    ),
                    _buildPreviewBadge(
                      context,
                      icon: FocusSymbolType.star.icon,
                      color:
                          FocusColorType.amber.resolveColor(theme.brightness),
                      label: 'Star',
                    ),
                    _buildPreviewBadge(
                      context,
                      icon: FocusSymbolType.hexagon.icon,
                      color:
                          FocusColorType.violet.resolveColor(theme.brightness),
                      label: 'Hexagon',
                    ),
                    _buildPreviewBadge(
                      context,
                      icon: FocusSymbolType.shield.icon,
                      color:
                          FocusColorType.emerald.resolveColor(theme.brightness),
                      label: 'Shield',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // How to Play Card
              AppCard(
                backgroundColor: customTheme.surfaceCardElevated,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to Play',
                      style: AppTypography.titleMedium.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildInstructionRow(
                      icon: Icons.search_rounded,
                      color: customTheme.accentCyan,
                      title: 'Identify the Target',
                      subtitle:
                          'Check the target header for the required shape and color combination.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildInstructionRow(
                      icon: Icons.shield_outlined,
                      color: customTheme.accentViolet,
                      title: 'Inhibit Distractors',
                      subtitle:
                          'Avoid tapping items that share only one feature. Both shape and color must match!',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildInstructionRow(
                      icon: Icons.timer_outlined,
                      color: customTheme.accentCyan,
                      title: 'Race the Clock',
                      subtitle:
                          'Find all targets before the timer expires without exceeding the allowed mistake limit.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Difficulty Settings Card
              AppCard(
                backgroundColor: customTheme.surfaceCard,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Starting Difficulty',
                            style: AppTypography.titleMedium.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        AppChip(
                          label:
                              'Level ${state.difficulty.level} · ${state.difficulty.tierName}',
                          colorType: AppChipColor.cyan,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Grid: ${state.config.gridRows}×${state.config.gridColumns} • Targets: ${state.config.sequenceLength} • Time: ${state.config.responseTimeLimit?.inSeconds}s',
                      style: AppTypography.bodySmall.copyWith(
                        color: customTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: customTheme.accentCyan,
                        inactiveTrackColor:
                            customTheme.accentCyan.withValues(alpha: 0.2),
                        thumbColor: customTheme.accentCyan,
                      ),
                      child: Slider(
                        value: state.difficulty.level.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: 'Level ${state.difficulty.level}',
                        onChanged: (val) {
                          onDifficultyChanged(GameDifficulty(val.round()));
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Start Action
              AppButton(
                key: const Key('focus_hunter_start_button'),
                label: 'Start Game',
                icon: Icons.play_arrow_rounded,
                variant: AppButtonVariant.primary,
                isFullWidth: true,
                onPressed: onStartPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewBadge(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: color.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
