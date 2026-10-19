import 'package:flutter/material.dart';
import 'package:brainforge/core/constants/app_colors.dart';
import 'package:brainforge/core/constants/app_spacing.dart';
import 'package:brainforge/core/constants/app_typography.dart';
import 'package:brainforge/core/theme/theme_extensions.dart';
import 'package:brainforge/core/widgets/app_button.dart';
import 'package:brainforge/core/widgets/app_card.dart';
import 'package:brainforge/features/games/memory_grid/logic/memory_grid_state.dart';
import 'package:brainforge/features/games/shared/domain/game_status.dart';

/// Results screen presenting performance metrics and replay actions upon session termination.
class MemoryGridResultView extends StatelessWidget {
  final MemoryGridState state;
  final VoidCallback onPlayAgainPressed;
  final VoidCallback onExitPressed;

  const MemoryGridResultView({
    super.key,
    required this.state,
    required this.onPlayAgainPressed,
    required this.onExitPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customTheme = context.brainForgeTheme;
    final result = state.result;

    final isSuccess = state.sessionState.status == GameStatus.completed;
    final isFailed = state.sessionState.status == GameStatus.failed;

    final IconData headerIcon;
    final Color headerColor;
    final String headline;
    final String subtitle;

    if (isSuccess) {
      headerIcon = Icons.emoji_events_rounded;
      headerColor = AppColors.amberReward;
      headline = 'Sequence Mastered!';
      subtitle = 'Excellent working memory and spatial sequence recall.';
    } else if (isFailed) {
      headerIcon = Icons.highlight_off_rounded;
      headerColor = AppColors.error;
      headline = 'Sequence Missed';
      subtitle = 'A tile was incorrect or time expired. Keep training!';
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
              // 1. Outcome Icon Banner
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: headerColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: headerColor.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: Icon(headerIcon, color: headerColor, size: 44),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 2. Headline & Subtitle
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
              const SizedBox(height: AppSpacing.xxl),

              // 3. Score & Metrics Card
              AppCard(
                backgroundColor: customTheme.surfaceCardElevated,
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    Text(
                      'Session Score',
                      style: AppTypography.titleMedium.copyWith(
                        color: customTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '$scoreValue',
                      style: AppTypography.displayLarge.copyWith(
                        color: isSuccess
                            ? customTheme.accentCyan
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Divider(color: customTheme.cardBorder),
                    const SizedBox(height: AppSpacing.md),
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
              const SizedBox(height: AppSpacing.xxl),

              // 4. Action Buttons
              AppButton(
                key: const Key('memory_grid_play_again_button'),
                label: 'Play Again',
                icon: Icons.refresh_rounded,
                isFullWidth: true,
                onPressed: onPlayAgainPressed,
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                key: const Key('memory_grid_return_catalog_button'),
                label: 'Return to Games',
                variant: AppButtonVariant.outline,
                isFullWidth: true,
                onPressed: onExitPressed,
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
          style: AppTypography.titleLarge.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: customTheme.textMuted,
          ),
        ),
      ],
    );
  }
}
