import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_keys.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_header.dart';

/// Daily Workout Overview & Intro screen.
class DailyWorkoutIntroScreen extends StatelessWidget {
  const DailyWorkoutIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customTheme = context.brainForgeTheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.huge),
          children: [
            const AppHeader(
              title: 'Daily Workout',
              subtitle: 'Structured Cognitive Session',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Banner
                  AppCard(
                    padding: AppSpacing.cardPadding,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [const Color(0xFF164E63), const Color(0xFF141926)]
                          : [const Color(0xFFCFFAFE), const Color(0xFFFFFFFF)],
                    ),
                    borderColor: isDark
                        ? AppColors.cyanPulse.withValues(alpha: 0.4)
                        : AppColors.lightSecondary.withValues(alpha: 0.3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const AppChip(
                              label: 'SESSION STRUCTURE',
                              icon: Icons.track_changes_rounded,
                              colorType: AppChipColor.cyan,
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: 14,
                                  color: customTheme.textMuted,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  '8–12 Minutes',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: customTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Daily Cognitive Routine',
                          style: AppTypography.displayMedium.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Daily workouts curate 3 to 4 complementary cognitive games to challenge memory, speed, attention, and flexibility in a single focused session.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: customTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  Text(
                    'SESSION BREAKDOWN',
                    style: AppTypography.labelSmall.copyWith(
                      color: customTheme.accentCyan,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  _WorkoutStepCard(
                    stepNumber: '1',
                    title: 'Warm-up: Visual Memory',
                    duration: '2-3 min',
                    description:
                        'Memory Grid sequence recall to activate visual retention.',
                    icon: Icons.grid_4x4_rounded,
                    color: customTheme.accentViolet,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _WorkoutStepCard(
                    stepNumber: '2',
                    title: 'Focus: Selective Search',
                    duration: '3-4 min',
                    description:
                        'Focus Hunter trials to calibrate concentration and visual filtering.',
                    icon: Icons.center_focus_strong_rounded,
                    color: customTheme.accentCyan,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const _WorkoutStepCard(
                    stepNumber: '3',
                    title: 'Speed: Cognitive Shift',
                    duration: '3-5 min',
                    description:
                        'Mind Switch challenges to evaluate mental flexibility under rule inversion.',
                    icon: Icons.alt_route_rounded,
                    color: AppColors.amberReward,
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Status notice
                  AppCard(
                    backgroundColor: customTheme.surfaceCardElevated,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.engineering_outlined,
                          color: AppColors.amberReward,
                          size: 22,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Workout Orchestrator Roadmap',
                                style: AppTypography.titleMedium.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Full workout sessions and daily streak synchronizers are scheduled for Phase 7 following game engine completion. For now, explore individual games in the catalog.',
                                style: AppTypography.bodySmall.copyWith(
                                  color: customTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Back to Home',
                          icon: Icons.home_rounded,
                          variant: AppButtonVariant.outline,
                          onPressed: () => context.go(AppKeys.homePath),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppButton(
                          label: 'View Games',
                          icon: Icons.grid_view_rounded,
                          variant: AppButtonVariant.secondary,
                          onPressed: () => context.go(AppKeys.gamesPath),
                        ),
                      ),
                    ],
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

class _WorkoutStepCard extends StatelessWidget {
  final String stepNumber;
  final String title;
  final String duration;
  final String description;
  final IconData icon;
  final Color color;

  const _WorkoutStepCard({
    required this.stepNumber,
    required this.title,
    required this.duration,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customTheme = context.brainForgeTheme;

    return AppCard(
      padding: AppSpacing.compactCardPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: AppTypography.labelMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleMedium.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      duration,
                      style: AppTypography.labelSmall.copyWith(
                        color: customTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  description,
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
