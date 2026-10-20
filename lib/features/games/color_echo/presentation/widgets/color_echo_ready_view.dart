import 'package:flutter/material.dart';
import 'package:brainforge/core/constants/app_spacing.dart';
import 'package:brainforge/core/constants/app_typography.dart';
import 'package:brainforge/core/theme/theme_extensions.dart';
import 'package:brainforge/core/widgets/app_button.dart';
import 'package:brainforge/core/widgets/app_card.dart';
import 'package:brainforge/core/widgets/app_chip.dart';
import 'package:brainforge/features/games/color_echo/domain/color_echo_config.dart';
import 'package:brainforge/features/games/color_echo/logic/color_echo_state.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';

/// Introduction and difficulty readiness screen for Color Echo.
class ColorEchoReadyView extends StatelessWidget {
  final ColorEchoState state;
  final ValueChanged<GameDifficulty> onDifficultyChanged;
  final VoidCallback onStartPressed;
  final VoidCallback onExitPressed;

  const ColorEchoReadyView({
    super.key,
    required this.state,
    required this.onDifficultyChanged,
    required this.onStartPressed,
    required this.onExitPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customTheme = context.brainForgeTheme;

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
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    key: const Key('color_echo_ready_back_button'),
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: onExitPressed,
                    tooltip: 'Back to Games',
                  ),
                  const Flexible(
                    child: AppChip(
                      label: 'Audio-Visual Memory',
                      colorType: AppChipColor.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Title Icon & Header
              Center(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: customTheme.accentViolet.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: Color(0xFFFFAB00),
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Color Echo',
                textAlign: TextAlign.center,
                style: AppTypography.displayMedium.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Observe the sequence of illuminated color pads and repeat it in exact order.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: customTheme.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // 4 Pads Mini Preview
              Center(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  alignment: WrapAlignment.center,
                  children: ColorEchoConfig.pads.map((pad) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: pad.baseColor.withValues(alpha: 0.3),
                        borderRadius: AppSpacing.roundedMd,
                        border: Border.all(
                          color: pad.activeColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(pad.icon, color: pad.activeColor, size: 16),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            pad.name,
                            style: AppTypography.bodySmall.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // How to Play Card
              AppCard(
                backgroundColor: customTheme.surfaceCardElevated,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to Play',
                      style: AppTypography.titleMedium.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildInstructionRow(
                      icon: Icons.visibility_rounded,
                      color: customTheme.accentCyan,
                      title: 'Watch the sequence',
                      subtitle:
                          'Colored pads will illuminate one by one. Input is paused during playback.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildInstructionRow(
                      icon: Icons.touch_app_rounded,
                      color: customTheme.accentViolet,
                      title: 'Echo the sequence',
                      subtitle:
                          'Tap the colored pads in the exact same order. Colors may repeat!',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildInstructionRow(
                      icon: Icons.trending_up_rounded,
                      color: const Color(0xFFFFAB00),
                      title: 'Adaptive Training',
                      subtitle:
                          'Win 3 consecutive qualifying games with ≥90% accuracy to promote to the next level.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Difficulty Settings Card
              AppCard(
                backgroundColor: customTheme.surfaceCard,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Starting Difficulty',
                            style: AppTypography.titleMedium.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        AppChip(
                          label:
                              'Level ${state.difficulty.level} · ${state.difficulty.tierName}',
                          colorType: AppChipColor.amber,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Sequence Length: ${state.config.sequenceLength ?? (3 + state.difficulty.level)} pads • Interval: ${state.config.presentationDuration.inMilliseconds}ms',
                      style: AppTypography.bodySmall.copyWith(
                        color: customTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFFFFAB00),
                        inactiveTrackColor:
                            customTheme.accentViolet.withValues(alpha: 0.2),
                        thumbColor: const Color(0xFFFFAB00),
                      ),
                      child: Slider(
                        value: state.difficulty.level.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: 'Level ${state.difficulty.level}',
                        onChanged: (val) {
                          onDifficultyChanged(GameDifficulty(val.round()));
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Start Action
              AppButton(
                key: const Key('color_echo_start_button'),
                label: 'Start Game',
                icon: Icons.play_arrow_rounded,
                variant: AppButtonVariant.primary,
                isFullWidth: true,
                onPressed: onStartPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
