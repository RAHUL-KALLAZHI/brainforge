import 'package:flutter/material.dart';
import 'package:brainforge/core/constants/app_colors.dart';
import 'package:brainforge/core/constants/app_spacing.dart';
import 'package:brainforge/core/constants/app_typography.dart';
import 'package:brainforge/core/theme/theme_extensions.dart';
import 'package:brainforge/core/widgets/app_button.dart';
import 'package:brainforge/core/widgets/app_card.dart';
import 'package:brainforge/features/games/shared/domain/adaptation_action.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';
import 'package:brainforge/features/games/mind_switch/logic/mind_switch_state.dart';

/// Results screen presenting scores, accuracy, latency, and adaptive difficulty
/// progression for Mind Switch.
class MindSwitchResultView extends StatelessWidget {
  final MindSwitchState state;
  final VoidCallback onPlayAgainPressed;
  final VoidCallback onReturnToGamePressed;
  final VoidCallback? onProceedToNextLevelPressed;
  final VoidCallback? onExitPressed;

  const MindSwitchResultView({
    super.key,
    required this.state,
    required this.onPlayAgainPressed,
    required this.onReturnToGamePressed,
    this.onProceedToNextLevelPressed,
    this.onExitPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customTheme = context.brainForgeTheme;
    final result = state.result;
    final isSuccess = result?.status == GameStatus.completed;
    final isFailed = result?.status == GameStatus.failed;

    final IconData headerIcon;
    final Color headerColor;
    final String headline;
    final String subtitle;

    if (isSuccess) {
      headerIcon = Icons.emoji_events_rounded;
      headerColor = AppColors.amberReward;
      headline = 'Cognitive Flexibility Mastered!';
      subtitle = 'Superb task-switching agility and interference suppression.';
    } else if (isFailed) {
      headerIcon = Icons.highlight_off_rounded;
      headerColor = AppColors.error;
      headline = 'Cognitive Switch Missed';
      subtitle =
          'Mistakes exceeded the allowable threshold for Level ${state.difficulty.level}. Keep training!';
    } else {
      headerIcon = Icons.flag_outlined;
      headerColor = customTheme.textMuted;
      headline = 'Session Abandoned';
      subtitle = 'Attempt was stopped early without completion score.';
    }

    final scoreValue = result?.score.scaledScore ?? 0;
    final accuracyPercent =
        result != null ? (result.score.accuracy * 100).round() : 0;
    final avgLatencyMs = result?.averageResponseTime.inMilliseconds ?? 0;

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
              // 1. Header Icon & Outcome
              Center(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: headerColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    headerIcon,
                    color: headerColor,
                    size: 64,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                headline,
                textAlign: TextAlign.center,
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: customTheme.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 2. Score & Primary Performance Card
              AppCard(
                padding: AppSpacing.cardPadding,
                child: Column(
                  children: [
                    Text(
                      'COMPOSITE SCORE',
                      style: AppTypography.labelSmall.copyWith(
                        color: customTheme.textMuted,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '$scoreValue',
                      style: AppTypography.displayLarge.copyWith(
                        color: isSuccess
                            ? customTheme.accentViolet
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Divider(height: AppSpacing.xl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(
                          label: 'Accuracy',
                          value: '$accuracyPercent%',
                          color: accuracyPercent >= 80
                              ? AppColors.success
                              : theme.colorScheme.onSurface,
                          context: context,
                        ),
                        _buildStatColumn(
                          label: 'Correct',
                          value: '${state.correctCount} / ${state.totalTrials}',
                          color: theme.colorScheme.onSurface,
                          context: context,
                        ),
                        _buildStatColumn(
                          label: 'Avg Speed',
                          value: '${avgLatencyMs}ms',
                          color: theme.colorScheme.onSurface,
                          context: context,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 3. Adaptive Difficulty Recommendation Card
              if (state.adaptationDecision != null) ...[
                _buildAdaptiveDecisionCard(context),
                const SizedBox(height: AppSpacing.lg),
              ],

              // 4. Action Buttons
              if (state.canProceedToNextLevel) ...[
                AppButton(
                  key: const Key('next_level_button'),
                  label:
                      'Proceed to Level ${state.recommendedDifficulty.level}',
                  icon: Icons.arrow_upward_rounded,
                  isFullWidth: true,
                  onPressed:
                      onProceedToNextLevelPressed ?? () => onPlayAgainPressed(),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              AppButton(
                key: const Key('play_again_button'),
                label: 'Play Again',
                icon: Icons.replay_rounded,
                isFullWidth: true,
                variant: state.canProceedToNextLevel
                    ? AppButtonVariant.outline
                    : AppButtonVariant.primary,
                onPressed: onPlayAgainPressed,
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                key: const Key('exit_to_catalog_button'),
                label: 'Return to Games',
                icon: Icons.dashboard_rounded,
                isFullWidth: true,
                variant: AppButtonVariant.ghost,
                onPressed: onReturnToGamePressed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn({
    required String label,
    required String value,
    required Color color,
    required BuildContext context,
  }) {
    final customTheme = context.brainForgeTheme;

    return Column(
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: customTheme.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAdaptiveDecisionCard(BuildContext context) {
    final theme = Theme.of(context);
    final customTheme = context.brainForgeTheme;
    final decision = state.adaptationDecision!;

    final Color badgeColor;
    final IconData badgeIcon;
    final String title;
    final String desc;

    switch (decision.action) {
      case AdaptationAction.promote:
        badgeColor = AppColors.success;
        badgeIcon = Icons.trending_up_rounded;
        title = 'Level Up Unlocked!';
        desc =
            'Excellent performance! Recommended: Level ${decision.targetDifficulty.level} (${decision.targetDifficulty.tierName}).';
        break;
      case AdaptationAction.demote:
        badgeColor = AppColors.amberReward;
        badgeIcon = Icons.trending_down_rounded;
        title = 'Difficulty Adjusted';
        desc =
            'Adjusting to Level ${decision.targetDifficulty.level} to maintain optimal training zone.';
        break;
      case AdaptationAction.maintain:
      default:
        badgeColor = customTheme.accentViolet;
        badgeIcon = Icons.check_circle_outline_rounded;
        title = 'Level Maintained';
        desc =
            'Solid practice session. Staying at Level ${state.difficulty.level} for consolidation.';
        break;
    }

    return AppCard(
      padding: AppSpacing.cardPadding,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(badgeIcon, color: badgeColor, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  desc,
                  style: AppTypography.bodySmall.copyWith(
                    color: customTheme.textMuted,
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
