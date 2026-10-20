import 'package:flutter/material.dart';
import 'package:brainforge/core/constants/app_colors.dart';
import 'package:brainforge/core/constants/app_spacing.dart';
import 'package:brainforge/core/constants/app_typography.dart';
import 'package:brainforge/core/theme/theme_extensions.dart';
import 'package:brainforge/core/widgets/app_button.dart';
import 'package:brainforge/core/widgets/app_card.dart';
import 'package:brainforge/features/games/color_echo/logic/color_echo_state.dart';
import 'package:brainforge/features/games/shared/domain/adaptation_action.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';

/// Results screen presenting performance metrics and adaptive actions upon session termination.
class ColorEchoResultView extends StatelessWidget {
  final ColorEchoState state;
  final VoidCallback onPlayAgainPressed;
  final VoidCallback onReturnToGamePressed;
  final VoidCallback? onProceedToNextLevelPressed;
  final VoidCallback? onExitPressed;

  const ColorEchoResultView({
    super.key,
    required this.state,
    required this.onPlayAgainPressed,
    required this.onReturnToGamePressed,
    this.onProceedToNextLevelPressed,
    this.onExitPressed,
  });

  VoidCallback get _effectiveReturnCallback => onReturnToGamePressed;

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '[ColorEchoResultView] Render: difficulty=L${state.difficulty.level}, '
      'decision=${state.adaptationDecision?.action.name ?? "none"}, '
      'target=L${state.adaptationDecision?.targetDifficulty.level ?? state.difficulty.level}',
    );

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
      headline = 'Sequence Echoed!';
      subtitle = 'Flawless audio-visual sequence recall and precision.';
    } else if (isFailed) {
      headerIcon = Icons.highlight_off_rounded;
      headerColor = AppColors.error;
      headline = 'Sequence Missed';
      subtitle = 'An incorrect pad was tapped or time expired. Keep training!';
    } else {
      headerIcon = Icons.flag_outlined;
      headerColor = customTheme.textMuted;
      headline = 'Session Abandoned';
      subtitle = 'Attempt was stopped early without completion score.';
    }

    final scoreValue = result?.score.scaledScore ?? 0;
    final accuracyPercent =
        result != null ? (result.score.accuracy * 100).round() : 0;
    final elapsedSeconds = result != null
        ? (result.totalDuration.inMilliseconds / 1000).toStringAsFixed(1)
        : '0.0';

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
                  child: Icon(headerIcon, color: headerColor, size: 56),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                headline,
                textAlign: TextAlign.center,
                style: AppTypography.displayMedium.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
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

              // 2. Score Badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: customTheme.surfaceCard,
                    borderRadius: AppSpacing.roundedLg,
                    border: Border.all(
                      color: customTheme.accentViolet.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'POINTS EARNED',
                        style: AppTypography.labelSmall.copyWith(
                          color: customTheme.accentCyan,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        scoreValue.toString(),
                        style: AppTypography.displayLarge.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 3. Performance Metrics
              AppCard(
                backgroundColor: customTheme.surfaceCardElevated,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetric(
                          label: 'Accuracy',
                          value: '$accuracyPercent%',
                          theme: theme,
                          customTheme: customTheme,
                        ),
                        _buildMetric(
                          label: 'Sequence',
                          value:
                              '${result?.score.correctCount ?? 0} / ${state.targetSequenceLength}',
                          theme: theme,
                          customTheme: customTheme,
                        ),
                        _buildMetric(
                          label: 'Duration',
                          value: '${elapsedSeconds}s',
                          theme: theme,
                          customTheme: customTheme,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 4. Adaptive Difficulty Feedback Banner (if applicable)
              if (_buildAdaptationBanner(context, theme, customTheme) != null)
                _buildAdaptationBanner(context, theme, customTheme)!,

              // 5. Action Buttons
              if (isSuccess && state.canProceedToNextLevel) ...[
                AppButton(
                  key: const Key('color_echo_proceed_next_level_button'),
                  label:
                      'Proceed to Level ${state.recommendedDifficulty.level}',
                  icon: Icons.arrow_forward_rounded,
                  variant: AppButtonVariant.primary,
                  isFullWidth: true,
                  onPressed: onProceedToNextLevelPressed,
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  key: const Key('color_echo_play_again_button'),
                  label: 'Replay Level ${state.playedDifficulty.level}',
                  icon: Icons.refresh_rounded,
                  variant: AppButtonVariant.secondary,
                  isFullWidth: true,
                  onPressed: onPlayAgainPressed,
                ),
              ] else if (isSuccess) ...[
                AppButton(
                  key: const Key('color_echo_play_again_button'),
                  label: 'Continue · Level ${state.playedDifficulty.level}',
                  icon: Icons.play_arrow_rounded,
                  variant: AppButtonVariant.primary,
                  isFullWidth: true,
                  onPressed: onPlayAgainPressed,
                ),
              ] else ...[
                AppButton(
                  key: const Key('color_echo_play_again_button'),
                  label: 'Play Again · Level ${state.playedDifficulty.level}',
                  icon: Icons.refresh_rounded,
                  variant: AppButtonVariant.primary,
                  isFullWidth: true,
                  onPressed: onPlayAgainPressed,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              AppButton(
                key: const Key('color_echo_return_game_button'),
                label: 'Return to Game',
                variant: AppButtonVariant.outline,
                isFullWidth: true,
                onPressed: _effectiveReturnCallback,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric({
    required String label,
    required String value,
    required ThemeData theme,
    required BrainForgeThemeExtension customTheme,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.headlineMedium.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: customTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget? _buildAdaptationBanner(
    BuildContext context,
    ThemeData theme,
    BrainForgeThemeExtension customTheme,
  ) {
    final decision = state.adaptationDecision;
    if (decision == null) return null;

    final IconData icon;
    final Color color;
    final String title;
    final String subtitle;

    switch (decision.action) {
      case AdaptationAction.promote:
        icon = Icons.trending_up_rounded;
        color = customTheme.accentCyan;
        title =
            'Difficulty Increased: Level ${decision.targetDifficulty.level} (${decision.targetDifficulty.tierName})';
        subtitle =
            'Your performance qualifies you for Level ${decision.targetDifficulty.level}. Ready for a longer sequence?';
        break;
      case AdaptationAction.demote:
        icon = Icons.trending_down_rounded;
        color = AppColors.amberReward;
        title =
            'Difficulty Adjusted: Level ${decision.targetDifficulty.level} (${decision.targetDifficulty.tierName})';
        subtitle = decision.reason;
        break;
      case AdaptationAction.insufficientData:
        icon = Icons.auto_awesome_rounded;
        color = customTheme.accentViolet;
        title = 'Adaptive Training Active';
        subtitle = decision.reason;
        break;
      case AdaptationAction.maintain:
        return null;
    }

    return Container(
      key: const Key('color_echo_adaptation_banner'),
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
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
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
