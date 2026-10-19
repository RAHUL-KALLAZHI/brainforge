import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_keys.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_header.dart';

/// Performance Analytics & Progress Dashboard screen.
class ProgressDashboardScreen extends StatelessWidget {
  const ProgressDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customTheme = context.brainForgeTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.huge),
          children: [
            const AppHeader(
              title: 'Progress',
              subtitle: 'Performance Analytics & Trends',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Empty State Hero Card
                  AppCard(
                    padding: AppSpacing.cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: customTheme.accentCyan
                                    .withValues(alpha: 0.15),
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
                  ),

                  const SizedBox(height: AppSpacing.xxl),

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
                          value: '-- %',
                          subtitle: '0 attempts recorded',
                          icon: Icons.check_circle_outline_rounded,
                          color: customTheme.accentViolet,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _MetricCard(
                          title: 'Median Speed',
                          value: '-- ms',
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
                          value: '0 Days',
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
                          subtitle: 'Total completed',
                          icon: Icons.task_alt_rounded,
                          color: customTheme.accentViolet,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xxl),

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
                          'Radar charts and domain evaluations (Memory, Attention, Speed, Flexibility) will activate once the local database is linked in Phase 4 and gameplay is logged.',
                          style: AppTypography.bodySmall.copyWith(
                            color: customTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            AppChip(label: 'Visual Memory: No Data'),
                            AppChip(label: 'Selective Attention: No Data'),
                            AppChip(label: 'Reaction Speed: No Data'),
                            AppChip(label: 'Flexibility: No Data'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
