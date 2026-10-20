import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_keys.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_header.dart';
import '../../games/shared/domain/game_attempt.dart';
import '../../games/shared/domain/game_status.dart';
import '../logic/progress_cubit.dart';
import '../logic/progress_state.dart';

/// Performance Analytics & Progress Dashboard screen.
class ProgressDashboardScreen extends StatelessWidget {
  final ProgressCubit? cubit;

  const ProgressDashboardScreen({super.key, this.cubit});

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<ProgressCubit>.value(
        value: cubit!,
        child: const _ProgressDashboardView(),
      );
    }
    return BlocProvider<ProgressCubit>(
      create: (_) => getIt<ProgressCubit>(),
      child: const _ProgressDashboardView(),
    );
  }
}

class _ProgressDashboardView extends StatelessWidget {
  const _ProgressDashboardView();

  @override
  Widget build(BuildContext context) {
    final customTheme = context.brainForgeTheme;

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<ProgressCubit, ProgressState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () => context.read<ProgressCubit>().loadProgress(),
              color: customTheme.accentCyan,
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.huge),
                children: [
                  const AppHeader(
                    title: 'Progress',
                    subtitle: 'Performance Analytics & Trends',
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (state is ProgressLoading)
                          const _LoadingPlaceholder()
                        else if (state is ProgressError)
                          _ErrorCard(
                            message: state.message,
                            onRetry: () =>
                                context.read<ProgressCubit>().loadProgress(),
                          )
                        else if (state is ProgressLoaded) ...[
                          _buildHeroCard(context, state.stats),
                          const SizedBox(height: AppSpacing.xxl),
                          _buildMetricsOverview(context, state.stats),
                          const SizedBox(height: AppSpacing.xxl),
                          if (state.stats.recentAttempts.isNotEmpty) ...[
                            _buildRecentAttempts(
                                context, state.stats.recentAttempts),
                            const SizedBox(height: AppSpacing.xxl),
                          ],
                          _buildCognitiveDomainBreakdown(context, state.stats),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, ProgressStats stats) {
    final theme = Theme.of(context);
    final customTheme = context.brainForgeTheme;

    if (!stats.hasData) {
      return AppCard(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: customTheme.accentCyan.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.insights_rounded,
                    color: customTheme.accentCyan,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analytics Awaiting Data',
                        style: AppTypography.titleLarge.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Play games to begin tracking metrics',
                        style: AppTypography.bodySmall.copyWith(
                          color: customTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'BrainForge computes objective metrics from your actual gameplay: sequence accuracy, median reaction speed, and adaptive difficulty progression. No mock or estimated stats are shown.',
              style: AppTypography.bodySmall.copyWith(
                color: customTheme.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Browse Games',
              icon: Icons.grid_view_rounded,
              variant: AppButtonVariant.primary,
              onPressed: () => context.go(AppKeys.gamesPath),
            ),
          ],
        ),
      );
    }

    return AppCard(
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: customTheme.accentCyan.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_graph_rounded,
                  color: customTheme.accentCyan,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gameplay Overview',
                      style: AppTypography.titleLarge.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${stats.totalAttempts} total attempts recorded',
                      style: AppTypography.bodySmall.copyWith(
                        color: customTheme.accentCyan,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Memory Grid: ${stats.memoryGridAttempts} attempts • ${stats.successfulAttempts} completed • ${stats.failedAttempts} failed'
            '${stats.abandonedAttempts > 0 ? ' • ${stats.abandonedAttempts} abandoned' : ''}',
            style: AppTypography.bodySmall.copyWith(
              color: customTheme.textMuted,
            ),
          ),
          if (stats.bestScore != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Personal Best Score: ${stats.bestScore} pts',
              style: AppTypography.bodyMedium.copyWith(
                color: customTheme.accentAmber,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Play Memory Grid',
            icon: Icons.play_arrow_rounded,
            variant: AppButtonVariant.primary,
            onPressed: () => context.go(AppKeys.memoryGridPath),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsOverview(BuildContext context, ProgressStats stats) {
    final customTheme = context.brainForgeTheme;

    final accuracyText = stats.averageAccuracy != null
        ? '${(stats.averageAccuracy! * 100).toStringAsFixed(1)}%'
        : '-- %';
    final speedText = stats.medianReactionTimeMs != null
        ? '${stats.medianReactionTimeMs} ms'
        : '-- ms';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'METRICS OVERVIEW',
          style: AppTypography.labelSmall.copyWith(
            color: customTheme.accentCyan,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Average Accuracy',
                value: accuracyText,
                subtitle: '${stats.totalAttempts} attempts recorded',
                icon: Icons.check_circle_outline_rounded,
                color: customTheme.accentViolet,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _MetricCard(
                title: 'Median Speed',
                value: speedText,
                subtitle: 'Reaction latency',
                icon: Icons.speed_rounded,
                color: customTheme.accentCyan,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Current Streak',
                value: '${stats.currentStreakDays} Days',
                subtitle: 'Play daily to build',
                icon: Icons.local_fire_department_rounded,
                color: customTheme.accentAmber,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _MetricCard(
                title: 'Workouts Done',
                value: '0',
                subtitle: 'Workout tracking in Phase 6',
                icon: Icons.task_alt_rounded,
                color: customTheme.accentViolet,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentAttempts(
    BuildContext context,
    List<GameAttempt> attempts,
  ) {
    final theme = Theme.of(context);
    final customTheme = context.brainForgeTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECENT ATTEMPTS',
          style: AppTypography.labelSmall.copyWith(
            color: customTheme.accentCyan,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...attempts.map((attempt) {
          final isCompleted = attempt.status == GameStatus.completed;
          final isFailed = attempt.status == GameStatus.failed;

          final statusChipColor = isCompleted
              ? AppChipColor.success
              : (isFailed ? AppChipColor.amber : AppChipColor.defaultColor);

          final statusLabel = isCompleted
              ? 'Completed'
              : (isFailed ? 'Failed' : 'Abandoned');

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              padding: AppSpacing.compactCardPadding,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: customTheme.accentViolet.withValues(alpha: 0.15),
                      borderRadius: AppSpacing.roundedSm,
                    ),
                    child: Icon(
                      Icons.grid_4x4_rounded,
                      color: customTheme.accentViolet,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Memory Grid',
                              style: AppTypography.titleMedium.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            AppChip(
                              label: 'Lvl ${attempt.difficultyLevel}',
                              colorType: AppChipColor.cyan,
                            ),
                            const Spacer(),
                            AppChip(
                              label: statusLabel,
                              colorType: statusChipColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${_formatAttemptDate(attempt.completedAt)} • Score: ${attempt.finalScore} pts • Accuracy: ${(attempt.accuracy * 100).round()}% • '
                          'Speed: ${attempt.medianResponseTimeMs != null ? '${attempt.medianResponseTimeMs} ms' : '--'}',
                          style: AppTypography.bodySmall.copyWith(
                            color: customTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  static String _formatAttemptDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final attemptDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute';

    if (attemptDay == today) {
      return 'Today $timeStr';
    } else if (attemptDay == yesterday) {
      return 'Yesterday $timeStr';
    } else {
      return '${dateTime.day}/${dateTime.month} $timeStr';
    }
  }

  Widget _buildCognitiveDomainBreakdown(
    BuildContext context,
    ProgressStats stats,
  ) {
    final theme = Theme.of(context);
    final customTheme = context.brainForgeTheme;

    final visualMemoryLabel = stats.memoryGridAttempts > 0
        ? 'Visual Memory: ${stats.memoryGridAttempts} logged'
        : 'Visual Memory: No Data';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COGNITIVE DOMAIN BREAKDOWN',
          style: AppTypography.labelSmall.copyWith(
            color: customTheme.accentCyan,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Domain Performance Index',
                style: AppTypography.titleMedium.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Live metrics recorded from your offline SQLite attempt database.',
                style: AppTypography.bodySmall.copyWith(
                  color: customTheme.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppChip(
                    label: visualMemoryLabel,
                    colorType: stats.memoryGridAttempts > 0
                        ? AppChipColor.success
                        : AppChipColor.defaultColor,
                  ),
                  const AppChip(
                    label: 'Selective Attention: Awaiting Game',
                    colorType: AppChipColor.defaultColor,
                  ),
                  AppChip(
                    label: stats.medianReactionTimeMs != null
                        ? 'Reaction Speed: ${stats.medianReactionTimeMs} ms'
                        : 'Reaction Speed: No Data',
                    colorType: stats.medianReactionTimeMs != null
                        ? AppChipColor.cyan
                        : AppChipColor.defaultColor,
                  ),
                  const AppChip(
                    label: 'Flexibility: Awaiting Game',
                    colorType: AppChipColor.defaultColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    final customTheme = context.brainForgeTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: CircularProgressIndicator(
          color: customTheme.accentCyan,
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customTheme = context.brainForgeTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline_rounded,
                  color: theme.colorScheme.error, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Database Error',
                style: AppTypography.titleMedium.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: AppTypography.bodySmall.copyWith(
              color: customTheme.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Retry',
            icon: Icons.refresh_rounded,
            variant: AppButtonVariant.secondary,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customTheme = context.brainForgeTheme;

    return AppCard(
      padding: AppSpacing.compactCardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.labelSmall.copyWith(
                  color: customTheme.textMuted,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.headlineLarge.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: customTheme.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
