import 'package:flutter/material.dart';
import 'package:brainforge/core/constants/app_colors.dart';
import 'package:brainforge/core/constants/app_spacing.dart';
import 'package:brainforge/core/constants/app_typography.dart';
import 'package:brainforge/core/theme/theme_extensions.dart';
import 'package:brainforge/core/widgets/app_chip.dart';
import 'package:brainforge/features/games/memory_grid/logic/memory_grid_state.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';

/// Top bar and status banner for the Memory Grid gameplay screen.
class MemoryGridHeader extends StatelessWidget {
  final MemoryGridState state;
  final VoidCallback onExitPressed;

  const MemoryGridHeader({
    super.key,
    required this.state,
    required this.onExitPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customTheme = context.brainForgeTheme;

    String statusText;
    Color statusColor;

    if (state.sessionState.status == GameStatus.countdown) {
      statusText = 'Get Ready: ${state.sessionState.countdownSecondsRemaining}';
      statusColor = AppColors.amberReward;
    } else if (state.sessionState.status == GameStatus.paused) {
      statusText = 'Game Paused';
      statusColor = customTheme.textMuted;
    } else if (state.isPreviewing) {
      statusText = 'Memorize the highlighted sequence...';
      statusColor = customTheme.accentCyan;
    } else if (state.isInputAllowed) {
      statusText =
          'Reproduce: ${state.currentStepIndex} of ${state.targetSequenceLength} tiles';
      statusColor = customTheme.accentViolet;
    } else {
      statusText = 'Observing sequence...';
      statusColor = customTheme.textMuted;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                key: const Key('memory_grid_exit_button'),
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: onExitPressed,
                tooltip: 'Exit Game',
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Memory Grid',
                  style: AppTypography.titleLarge.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              AppChip(
                label:
                    'Level ${state.difficulty.level} (${state.difficulty.tierName})',
                colorType: AppChipColor.violet,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: AppSpacing.roundedMd,
              border: Border.all(
                color: statusColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  state.isPreviewing
                      ? Icons.visibility_rounded
                      : state.isInputAllowed
                          ? Icons.touch_app_rounded
                          : Icons.timer_rounded,
                  color: statusColor,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    statusText,
                    style: AppTypography.titleMedium.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (state.isInputAllowed &&
                    state.sessionState.remainingResponseTime > Duration.zero)
                  Text(
                    '${state.sessionState.remainingResponseTime.inSeconds}s',
                    style: AppTypography.labelMedium.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
