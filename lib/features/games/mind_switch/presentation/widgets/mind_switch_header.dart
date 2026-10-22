import 'package:flutter/material.dart';
import 'package:brainforge/core/constants/app_colors.dart';
import 'package:brainforge/core/constants/app_spacing.dart';
import 'package:brainforge/core/constants/app_typography.dart';
import 'package:brainforge/core/theme/theme_extensions.dart';
import 'package:brainforge/core/widgets/app_chip.dart';
import 'package:brainforge/features/games/mind_switch/domain/mind_switch_challenge.dart';
import 'package:brainforge/features/games/mind_switch/logic/mind_switch_state.dart';

/// Top bar, trial progress, active rule banner, and timer for Mind Switch.
class MindSwitchHeader extends StatelessWidget {
  final MindSwitchState state;
  final VoidCallback onExitPressed;

  const MindSwitchHeader({
    super.key,
    required this.state,
    required this.onExitPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customTheme = context.brainForgeTheme;

    final rule = state.currentRule;
    final isColorRule = rule == MindSwitchRule.color;
    final ruleAccent =
        isColorRule ? customTheme.accentCyan : customTheme.accentAmber;

    // Remaining timer fraction (0.0 to 1.0)
    final double timeFraction;
    if (state.trialTimeLimit.inMilliseconds > 0) {
      timeFraction = (state.trialTimeRemaining.inMilliseconds /
              state.trialTimeLimit.inMilliseconds)
          .clamp(0.0, 1.0);
    } else {
      timeFraction = 1.0;
    }

    final timerBarColor = timeFraction < 0.25
        ? AppColors.error
        : (timeFraction < 0.5 ? AppColors.amberReward : ruleAccent);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Bar with Exit and Difficulty Badge
          Row(
            children: [
              IconButton(
                key: const Key('mind_switch_exit_button'),
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: onExitPressed,
                tooltip: 'Exit Game',
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Mind Switch',
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
          const SizedBox(height: AppSpacing.xs),

          // Trial Progress & Mistakes Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trial ${state.currentTrialIndex + 1} of ${state.totalTrials}',
                style: AppTypography.labelMedium.copyWith(
                  color: customTheme.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: state.mistakeCount > 0
                        ? AppColors.error
                        : customTheme.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Mistakes: ${state.mistakeCount} / ${state.challenge.maxMistakesAllowed}',
                    style: AppTypography.labelMedium.copyWith(
                      color: state.mistakeCount > 0
                          ? AppColors.error
                          : customTheme.textMuted,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Timer Progress Indicator Bar
          if (state.isPlaying) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: timeFraction,
                minHeight: 6,
                backgroundColor: customTheme.surfaceCard,
                valueColor: AlwaysStoppedAnimation<Color>(timerBarColor),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Active Rule Banner
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: ruleAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ruleAccent.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: ruleAccent.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    rule.icon,
                    color: ruleAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule.shortLabel,
                        style: AppTypography.labelSmall.copyWith(
                          color: ruleAccent,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Text(
                        rule.instruction,
                        style: AppTypography.bodySmall.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
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
