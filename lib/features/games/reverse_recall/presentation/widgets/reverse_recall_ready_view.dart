import 'package:flutter/material.dart';
import 'package:brainforge/core/constants/app_spacing.dart';
import 'package:brainforge/core/constants/app_typography.dart';
import 'package:brainforge/core/theme/theme_extensions.dart';
import 'package:brainforge/core/widgets/app_button.dart';
import 'package:brainforge/core/widgets/app_card.dart';
import 'package:brainforge/core/widgets/app_chip.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import 'package:brainforge/features/games/reverse_recall/logic/reverse_recall_state.dart';

/// Introduction, instructions, and difficulty selector view for Reverse Recall.
class ReverseRecallReadyView extends StatelessWidget {
  final ReverseRecallState state;
  final ValueChanged<GameDifficulty> onDifficultyChanged;
  final VoidCallback onStartPressed;
  final VoidCallback onExitPressed;

  const ReverseRecallReadyView({
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
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    key: const Key('reverse_recall_ready_back_button'),
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
                    color: customTheme.accentCyan.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.swap_horiz_rounded,
                    color: customTheme.accentCyan,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Reverse Recall',
                textAlign: TextAlign.center,
                style: AppTypography.displayMedium.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Observe the sequence of numbers and enter them backward in reverse order.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: customTheme.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Objective & Mechanics Card
              AppCard(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.psychology_rounded,
                          color: customTheme.accentCyan,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'HOW IT WORKS',
                          style: AppTypography.labelSmall.copyWith(
                            color: customTheme.accentCyan,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '1. Numbers appear one by one on the screen.\n'
                      '2. Memorize the sequence in your working memory.\n'
                      '3. Use the keypad to enter the numbers in REVERSE order (last shown first).',
                      style: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.onSurface,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: customTheme.surfaceCardElevated,
                        borderRadius: AppSpacing.roundedSm,
                        border: Border.all(
                          color: customTheme.accentCyan.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            color: customTheme.accentCyan,
                            size: 16,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              'Example: Shown [3 → 7 → 2] ⟹ Enter [2 → 7 → 3]',
                              style: AppTypography.labelSmall.copyWith(
                                color: customTheme.accentCyan,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Metrics Preview
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          Text(
                            'SEQUENCE',
                            style: AppTypography.labelSmall.copyWith(
                              color: customTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            '${state.targetSequenceLength} Digits',
                            style: AppTypography.titleMedium.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          Text(
                            'EXPOSURE',
                            style: AppTypography.labelSmall.copyWith(
                              color: customTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            '${state.config.presentationDuration.inMilliseconds}ms',
                            style: AppTypography.titleMedium.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          Text(
                            'TIME LIMIT',
                            style: AppTypography.labelSmall.copyWith(
                              color: customTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            '20s',
                            style: AppTypography.titleMedium.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Difficulty Selector Card
              AppCard(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'DIFFICULTY LEVEL',
                          style: AppTypography.labelSmall.copyWith(
                            color: customTheme.textMuted,
                            letterSpacing: 1.1,
                          ),
                        ),
                        AppChip(
                          label:
                              'Level ${state.difficulty.level} · ${state.difficulty.tierName}',
                          colorType: AppChipColor.cyan,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Slider(
                      value: state.difficulty.level.toDouble(),
                      min: GameDifficulty.minLevel.toDouble(),
                      max: GameDifficulty.maxLevel.toDouble(),
                      divisions: 9,
                      activeColor: customTheme.accentCyan,
                      inactiveColor: customTheme.surfaceCardElevated,
                      onChanged: (val) {
                        onDifficultyChanged(GameDifficulty(val.round()));
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'L1 (Beginner)',
                          style: AppTypography.bodySmall.copyWith(
                            color: customTheme.textMuted,
                          ),
                        ),
                        Text(
                          'L10 (Master)',
                          style: AppTypography.bodySmall.copyWith(
                            color: customTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Start Game Action Button
              AppButton(
                key: const Key('start_reverse_recall_button'),
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
}
