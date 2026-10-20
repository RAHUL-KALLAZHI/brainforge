import 'package:flutter/material.dart';
import 'package:brainforge/core/constants/app_colors.dart';
import 'package:brainforge/core/constants/app_spacing.dart';
import 'package:brainforge/core/constants/app_typography.dart';
import 'package:brainforge/core/theme/theme_extensions.dart';
import 'package:brainforge/core/widgets/app_chip.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';
import '../../logic/vanishing_cards_state.dart';

/// Header bar displaying level, timer, mistakes, and exit action for Vanishing Cards.
class VanishingCardsHeader extends StatelessWidget {
  final VanishingCardsState state;
  final VoidCallback onExitPressed;

  const VanishingCardsHeader({
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
      statusText = 'Memorize card locations!';
      statusColor = customTheme.accentViolet;
    } else if (state.isInputAllowed) {
      statusText =
          'Recalled: ${state.cardsRecalledCount} of ${state.cardsToRecallCount}';
      statusColor = customTheme.accentViolet;
    } else {
      statusText = 'Vanishing Cards';
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
                key: const Key('vanishing_cards_exit_button'),
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: onExitPressed,
                tooltip: 'Exit Game',
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Vanishing Cards',
                  style: AppTypography.titleLarge.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              AppChip(
                label: 'Lvl ${state.difficulty.level}',
                colorType: AppChipColor.violet,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status text
              Text(
                statusText,
                style: AppTypography.labelMedium.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),

              // Mistakes indicator & Timer
              Row(
                children: [
                  if (state.maxErrorsAllowed > 0 && !state.isPreviewing) ...[
                    Row(
                      children: List.generate(
                        state.maxErrorsAllowed,
                        (index) {
                          final isMistake = index < state.mistakesCount;
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: isMistake
                                  ? AppColors.error
                                  : customTheme.textMuted
                                      .withValues(alpha: 0.3),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  if (state.isInputAllowed &&
                      state.sessionState.remainingResponseTime >
                          Duration.zero) ...[
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: customTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${state.sessionState.remainingResponseTime.inSeconds}s',
                      style: AppTypography.labelMedium.copyWith(
                        color: state.sessionState.remainingResponseTime
                                    .inSeconds <=
                                3
                            ? AppColors.error
                            : customTheme.textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
