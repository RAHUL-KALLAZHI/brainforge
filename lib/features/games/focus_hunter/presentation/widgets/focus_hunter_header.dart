import 'package:flutter/material.dart';
import 'package:brainforge/core/constants/app_colors.dart';
import 'package:brainforge/core/constants/app_spacing.dart';
import 'package:brainforge/core/constants/app_typography.dart';
import 'package:brainforge/core/theme/theme_extensions.dart';
import 'package:brainforge/core/widgets/app_chip.dart';
import 'package:brainforge/features/games/focus_hunter/logic/focus_hunter_state.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';

/// Top bar and status banner for the Focus Hunter gameplay screen.
class FocusHunterHeader extends StatelessWidget {
  final FocusHunterState state;
  final VoidCallback onExitPressed;

  const FocusHunterHeader({
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
    } else if (state.isInputAllowed) {
      statusText =
          'Targets: ${state.targetsFound} of ${state.targetCount} found';
      statusColor = customTheme.accentCyan;
    } else {
      statusText = 'Scanning board...';
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
                key: const Key('focus_hunter_exit_button'),
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: onExitPressed,
                tooltip: 'Exit Game',
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Focus Hunter',
                  style: AppTypography.titleLarge.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              AppChip(
                label:
                    'Level ${state.difficulty.level} (${state.difficulty.tierName})',
                colorType: AppChipColor.amber,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
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
                  state.isInputAllowed
                      ? Icons.center_focus_strong_rounded
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
                if (state.isInputAllowed) ...[
                  // Mistakes indicator
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: state.mistakesCount > 0
                            ? AppColors.error
                            : customTheme.textMuted,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${state.mistakesCount}/${state.maxErrorsAllowed}',
                        style: AppTypography.labelMedium.copyWith(
                          color: state.mistakesCount > 0
                              ? AppColors.error
                              : customTheme.textMuted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.md),
                  if (state.sessionState.remainingResponseTime > Duration.zero)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${state.sessionState.remainingResponseTime.inSeconds}s',
                          style: AppTypography.labelMedium.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
