import 'package:flutter/material.dart';
import 'package:brainforge/core/constants/app_spacing.dart';
import 'package:brainforge/core/constants/app_typography.dart';
import 'package:brainforge/core/theme/theme_extensions.dart';
import 'package:brainforge/core/widgets/app_button.dart';
import 'package:brainforge/core/widgets/app_card.dart';
import 'package:brainforge/core/widgets/app_chip.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import '../../logic/vanishing_cards_state.dart';

/// Pre-game introduction and difficulty setup screen for Vanishing Cards.
class VanishingCardsReadyView extends StatelessWidget {
  final VanishingCardsState state;
  final ValueChanged<GameDifficulty> onDifficultyChanged;
  final VoidCallback onStartPressed;
  final VoidCallback onExitPressed;

  const VanishingCardsReadyView({
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
              // 1. Top Navigation Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    key: const Key('vanishing_cards_ready_back_button'),
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: onExitPressed,
                    tooltip: 'Back to Games',
                  ),
                  const Flexible(
                    child: AppChip(
                      label: 'Spatial Recall',
                      colorType: AppChipColor.violet,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // 2. Title Icon & Header
              Center(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: customTheme.accentViolet.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.style_rounded,
                    color: customTheme.accentViolet,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Vanishing Cards',
                textAlign: TextAlign.center,
                style: AppTypography.headlineLarge.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Study revealed cards and recall their spatial locations once hidden.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: customTheme.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 3. Difficulty Tier & Level Slider
              AppCard(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Difficulty Level',
                            style: AppTypography.labelLarge.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        AppChip(
                          label:
                              'Level ${state.difficulty.level} · ${state.difficulty.tierName}',
                          colorType: AppChipColor.violet,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: customTheme.accentViolet,
                        inactiveTrackColor:
                            customTheme.accentViolet.withValues(alpha: 0.2),
                        thumbColor: customTheme.accentViolet,
                        overlayColor:
                            customTheme.accentViolet.withValues(alpha: 0.12),
                      ),
                      child: Slider(
                        value: state.difficulty.level.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: 'Lvl ${state.difficulty.level}',
                        onChanged: (val) {
                          onDifficultyChanged(GameDifficulty(val.round()));
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    // Level configuration summary chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetricChip(
                          context,
                          '${state.challenge.gridRows}×${state.challenge.gridColumns} Cards',
                          Icons.grid_view_rounded,
                        ),
                        _buildMetricChip(
                          context,
                          'Recall ${state.challenge.targetCards.length}',
                          Icons.touch_app_rounded,
                        ),
                        _buildMetricChip(
                          context,
                          '${(state.challenge.previewDuration.inMilliseconds / 1000).toStringAsFixed(1)}s Study',
                          Icons.visibility_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 4. Instructions Card
              AppCard(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to Play',
                      style: AppTypography.titleMedium.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildStepRow(
                      context,
                      '1',
                      'Examine the cards during the preview study window.',
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _buildStepRow(
                      context,
                      '2',
                      'Cards vanish and flip face-down when study time expires.',
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _buildStepRow(
                      context,
                      '3',
                      'Tap the exact grid location of each requested target card.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // 5. Start Action Button
              AppButton(
                key: const Key('vanishing_cards_start_button'),
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

  Widget _buildMetricChip(BuildContext context, String text, IconData icon) {
    final customTheme = context.brainForgeTheme;
    return Row(
      children: [
        Icon(icon, size: 14, color: customTheme.accentViolet),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTypography.bodySmall.copyWith(
            color: customTheme.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildStepRow(BuildContext context, String step, String text) {
    final customTheme = context.brainForgeTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: customTheme.accentViolet.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Text(
            step,
            style: AppTypography.labelSmall.copyWith(
              color: customTheme.accentViolet,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: customTheme.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}
