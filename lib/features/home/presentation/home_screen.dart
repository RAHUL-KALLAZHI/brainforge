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

/// Home Dashboard screen for BrainForge.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
            // Welcome Header & Branding
            AppHeader(
              title: 'BrainForge',
              subtitle: 'Train Your Mind • Daily Cognitive Practice',
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.amberReward.withValues(alpha: 0.15),
                  borderRadius: AppSpacing.roundedRound,
                  border: Border.all(
                    color: AppColors.amberReward.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 16,
                      color: AppColors.amberReward,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '0 Day Streak',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.amberRewardLight
                            : const Color(0xFFB45309),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prominent Daily Workout Card
                  AppCard(
                    padding: AppSpacing.cardPadding,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0xFF1E1B4B),
                              const Color(0xFF141926),
                            ]
                          : [
                              const Color(0xFFEDE9FE),
                              const Color(0xFFFFFFFF),
                            ],
                    ),
                    borderColor: isDark
                        ? AppColors.electricViolet.withValues(alpha: 0.4)
                        : AppColors.lightPrimary.withValues(alpha: 0.3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: [
                            const AppChip(
                              label: 'RECOMMENDED',
                              icon: Icons.auto_awesome_rounded,
                              colorType: AppChipColor.violet,
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: 14,
                                  color: customTheme.textMuted,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  '~8-12 min',
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
                          "Today's Workout",
                          style: AppTypography.displayMedium.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'A balanced cognitive session targeting memory, concentration, and reaction speed.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: customTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppButton(
                          label: 'Start Workout',
                          icon: Icons.play_arrow_rounded,
                          variant: AppButtonVariant.primary,
                          isFullWidth: true,
                          onPressed: () => context.go(AppKeys.workoutPath),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Quick Challenge Section
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      Text(
                        'PRACTICE DOMAINS',
                        style: AppTypography.labelSmall.copyWith(
                          color: customTheme.accentCyan,
                          letterSpacing: 1.2,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go(AppKeys.gamesPath),
                        child: Text(
                          'View All Games',
                          style: AppTypography.labelSmall.copyWith(
                            color: customTheme.accentViolet,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  Row(
                    children: [
                      // Memory Domain Card
                      Expanded(
                        child: AppCard(
                          padding: AppSpacing.cardPadding,
                          onTap: () => context.go(AppKeys.gamesPath),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: customTheme.accentViolet
                                      .withValues(alpha: 0.15),
                                  borderRadius: AppSpacing.roundedSm,
                                ),
                                child: Icon(
                                  Icons.grid_4x4_rounded,
                                  color: customTheme.accentViolet,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Memory',
                                style: AppTypography.titleMedium.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                'Visual & Working Recall',
                                style: AppTypography.bodySmall.copyWith(
                                  color: customTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      // Focus Domain Card
                      Expanded(
                        child: AppCard(
                          padding: AppSpacing.cardPadding,
                          onTap: () => context.go(AppKeys.gamesPath),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: customTheme.accentCyan
                                      .withValues(alpha: 0.15),
                                  borderRadius: AppSpacing.roundedSm,
                                ),
                                child: Icon(
                                  Icons.center_focus_strong_rounded,
                                  color: customTheme.accentCyan,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Attention',
                                style: AppTypography.titleMedium.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                'Selective Target Search',
                                style: AppTypography.bodySmall.copyWith(
                                  color: customTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Progress Summary with Meaningful Empty State
                  Text(
                    'PROGRESS OVERVIEW',
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
                        Row(
                          children: [
                            Icon(
                              Icons.analytics_outlined,
                              color: customTheme.accentCyan,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'No Activity Yet',
                              style: AppTypography.titleMedium.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Complete your first practice session or daily workout to unlock accuracy trends, reaction times, and performance analytics.',
                          style: AppTypography.bodySmall.copyWith(
                            color: customTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppButton(
                          label: 'Explore Games',
                          icon: Icons.arrow_forward_rounded,
                          variant: AppButtonVariant.outline,
                          onPressed: () => context.go(AppKeys.gamesPath),
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
