import 'package:flutter/material.dart';
import 'package:brainforge/core/constants/app_spacing.dart';
import 'package:brainforge/core/constants/app_typography.dart';
import 'package:brainforge/core/theme/theme_extensions.dart';
import 'package:brainforge/core/widgets/app_button.dart';
import 'package:brainforge/core/widgets/app_card.dart';
import 'package:brainforge/core/widgets/app_chip.dart';
import 'package:brainforge/features/games/memory_grid/logic/memory_grid_state.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';

/// Introduction and difficulty readiness screen for Memory Grid.
class MemoryGridReadyView extends StatelessWidget {
  final MemoryGridState state;
  final ValueChanged<GameDifficulty> onDifficultyChanged;
  final VoidCallback onStartPressed;
  final VoidCallback onExitPressed;

  const MemoryGridReadyView({
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
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: onExitPressed,
                    tooltip: 'Back to Games',
                  ),
                  const Flexible(
                    child: AppChip(
                      label: 'Working Memory',
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
                    color: customTheme.accentViolet.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.grid_4x4_rounded,
                    color: customTheme.accentViolet,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Memory Grid',
                textAlign: TextAlign.center,
                style: AppTypography.displayMedium.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Memorize the illuminated sequence and reproduce it in exact order.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: customTheme.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

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
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildRuleStep(
                      number: '1',
                      title: 'Observe',
                      description: 'Tiles illuminate one-by-one in sequence.',
                      customTheme: customTheme,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildRuleStep(
                      number: '2',
                      title: 'Recall',
                      description: 'Tap each tile in the exact recorded order.',
                      customTheme: customTheme,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildRuleStep(
                      number: '3',
                      title: 'Master',
                      description: 'Complete the sequence accurately to score.',
                      customTheme: customTheme,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Difficulty Picker
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Difficulty Level',
                          style: AppTypography.titleMedium.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Adapts to recent performance',
                          style: AppTypography.labelSmall.copyWith(
                            color: customTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 36, minHeight: 36),
                        onPressed: state.difficulty.level > 1
                            ? () =>
                                onDifficultyChanged(state.difficulty.decrease())
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs),
                        child: Text(
                          'Level ${state.difficulty.level}',
                          style: AppTypography.titleMedium.copyWith(
                            color: customTheme.accentCyan,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 36, minHeight: 36),
                        onPressed: state.difficulty.level < 10
                            ? () =>
                                onDifficultyChanged(state.difficulty.increase())
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Start CTA
              AppButton(
                key: const Key('memory_grid_start_game_button'),
                label: 'Start Game',
                icon: Icons.play_arrow_rounded,
                isFullWidth: true,
                onPressed: onStartPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleStep({
    required String number,
    required String title,
    required String description,
    required BrainForgeThemeExtension customTheme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: customTheme.accentCyan.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: AppTypography.labelSmall.copyWith(
              color: customTheme.accentCyan,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTypography.bodySmall.copyWith(
                color: customTheme.textMuted,
              ),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
