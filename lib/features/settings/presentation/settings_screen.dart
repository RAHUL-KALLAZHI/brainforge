import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_header.dart';
import '../logic/settings_cubit.dart';
import '../logic/settings_state.dart';

/// Settings & Preferences screen for BrainForge.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
              title: 'Settings',
              subtitle: 'Preferences & Application Controls',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section: Appearance & Theme
                  Text(
                    'APPEARANCE',
                    style: AppTypography.labelSmall.copyWith(
                      color: customTheme.accentCyan,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  BlocBuilder<SettingsCubit, SettingsState>(
                    builder: (context, state) {
                      return AppCard(
                        padding: AppSpacing.cardPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.palette_outlined,
                                  color: customTheme.accentViolet,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Theme Mode',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Select default dark mode or clean light mode',
                              style: AppTypography.bodySmall.copyWith(
                                color: customTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Expanded(
                                  child: _ThemeOptionTile(
                                    label: 'Dark Mode',
                                    icon: Icons.dark_mode_outlined,
                                    isSelected:
                                        state.themeMode == ThemeMode.dark,
                                    onTap: () => context
                                        .read<SettingsCubit>()
                                        .setThemeMode(ThemeMode.dark),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: _ThemeOptionTile(
                                    label: 'Light Mode',
                                    icon: Icons.light_mode_outlined,
                                    isSelected:
                                        state.themeMode == ThemeMode.light,
                                    onTap: () => context
                                        .read<SettingsCubit>()
                                        .setThemeMode(ThemeMode.light),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: _ThemeOptionTile(
                                    label: 'System',
                                    icon: Icons.brightness_auto_outlined,
                                    isSelected:
                                        state.themeMode == ThemeMode.system,
                                    onTap: () => context
                                        .read<SettingsCubit>()
                                        .setThemeMode(ThemeMode.system),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Section: Feedback & Audio
                  Text(
                    'FEEDBACK & AUDIO',
                    style: AppTypography.labelSmall.copyWith(
                      color: customTheme.accentCyan,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  BlocBuilder<SettingsCubit, SettingsState>(
                    builder: (context, state) {
                      return AppCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        child: Column(
                          children: [
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              secondary: Icon(
                                state.soundEnabled
                                    ? Icons.volume_up_outlined
                                    : Icons.volume_off_outlined,
                                color: customTheme.accentViolet,
                              ),
                              title: Text(
                                'Sound Effects',
                                style: AppTypography.titleMedium.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              subtitle: Text(
                                'Game tones and celebratory audio cues',
                                style: AppTypography.bodySmall.copyWith(
                                  color: customTheme.textMuted,
                                ),
                              ),
                              value: state.soundEnabled,
                              activeTrackColor: customTheme.accentCyan,
                              onChanged: (val) => context
                                  .read<SettingsCubit>()
                                  .setSoundEnabled(val),
                            ),
                            Divider(color: customTheme.cardBorder, height: 1),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              secondary: Icon(
                                state.hapticEnabled
                                    ? Icons.vibration_outlined
                                    : Icons.smartphone_outlined,
                                color: customTheme.accentViolet,
                              ),
                              title: Text(
                                'Haptic Feedback',
                                style: AppTypography.titleMedium.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              subtitle: Text(
                                'Vibration feedback on tap and sequence confirmation',
                                style: AppTypography.bodySmall.copyWith(
                                  color: customTheme.textMuted,
                                ),
                              ),
                              value: state.hapticEnabled,
                              activeTrackColor: customTheme.accentCyan,
                              onChanged: (val) => context
                                  .read<SettingsCubit>()
                                  .setHapticEnabled(val),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Section: Privacy & Storage
                  Text(
                    'PRIVACY & OFFLINE GUARANTEE',
                    style: AppTypography.labelSmall.copyWith(
                      color: customTheme.accentCyan,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.lock_outline,
                              color: AppColors.success,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '100% Offline & Private',
                              style: AppTypography.titleMedium.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const Spacer(),
                            const AppChip(
                              label: 'Offline-First',
                              colorType: AppChipColor.success,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'BrainForge stores all training logs, difficulty calibrations, and performance records strictly on your device. No cloud analytics, user accounts, or remote trackers are required.',
                          style: AppTypography.bodySmall.copyWith(
                            color: customTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Section: About & Version
                  Text(
                    'ABOUT',
                    style: AppTypography.labelSmall.copyWith(
                      color: customTheme.accentCyan,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: customTheme.accentViolet
                                    .withValues(alpha: 0.15),
                                borderRadius: AppSpacing.roundedSm,
                              ),
                              child: Icon(
                                Icons.psychology_outlined,
                                color: customTheme.accentViolet,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BrainForge',
                                  style: AppTypography.titleLarge.copyWith(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Train Your Mind • v1.0.0+1',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: customTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'BrainForge is built with Flutter and Dart. Designed for cognitive practice, visual memory, and focus tracking.',
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
          ],
        ),
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final customTheme = context.brainForgeTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final border = isSelected
        ? Border.all(color: customTheme.accentCyan, width: 1.5)
        : Border.all(color: customTheme.cardBorder, width: 1.0);

    final bg = isSelected
        ? (isDark
            ? customTheme.accentViolet.withValues(alpha: 0.25)
            : customTheme.accentViolet.withValues(alpha: 0.12))
        : customTheme.surfaceCardElevated;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.roundedMd,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppSpacing.roundedMd,
            border: border,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color:
                    isSelected ? customTheme.accentCyan : customTheme.textMuted,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected
                      ? (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary)
                      : customTheme.textMuted,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
