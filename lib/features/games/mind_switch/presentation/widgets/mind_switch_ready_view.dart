import 'package:flutter/material.dart';
import 'package:brainforge/core/constants/app_colors.dart';
import 'package:brainforge/core/constants/app_spacing.dart';
import 'package:brainforge/core/constants/app_typography.dart';
import 'package:brainforge/core/theme/theme_extensions.dart';
import 'package:brainforge/core/widgets/app_button.dart';
import 'package:brainforge/core/widgets/app_card.dart';
import 'package:brainforge/core/widgets/app_chip.dart';
import 'package:brainforge/features/games/shared/domain/game_difficulty.dart';
import 'package:brainforge/features/games/mind_switch/domain/mind_switch_challenge.dart';
import 'package:brainforge/features/games/mind_switch/domain/mind_switch_config.dart';
import 'package:brainforge/features/games/mind_switch/logic/mind_switch_state.dart';

/// Introduction, instructions, and difficulty selector view for Mind Switch.
class MindSwitchReadyView extends StatelessWidget {
  final MindSwitchState state;
  final ValueChanged<GameDifficulty> onDifficultyChanged;
  final VoidCallback onStartPressed;
  final VoidCallback onExitPressed;

  const MindSwitchReadyView({
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
    final totalTrials =
        MindSwitchConfig.totalTrialsForDifficulty(state.difficulty);
    final timeLimit =
        MindSwitchConfig.trialTimeLimitForDifficulty(state.difficulty);
    final timeLimitSec = (timeLimit.inMilliseconds / 1000).toStringAsFixed(1);
    final maxMistakes =
        MindSwitchConfig.maxMistakesForDifficulty(state.difficulty);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xxl,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    key: const Key('mind_switch_ready_back_button'),
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: onExitPressed,
                    tooltip: 'Back to Games',
                  ),
                  const Flexible(
                    child: AppChip(
                      label: 'Cognitive Flexibility',
                      colorType: AppChipColor.violet,
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
                  child: Icon(
                    Icons.alt_route_rounded,
                    color: customTheme.accentViolet,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Mind Switch',
                textAlign: TextAlign.center,
                style: AppTypography.displayMedium.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Adapt rapidly to shifting Stroop matching rules and overcome cognitive interference.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: customTheme.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Objective & Mechanics Card
              AppCard(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.psychology_rounded,
                          color: customTheme.accentViolet,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'How to Play',
                          style: AppTypography.titleMedium.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildRuleRow(
                      icon: Icons.palette_rounded,
                      iconColor: customTheme.accentCyan,
                      title: 'Match Ink Color',
                      description:
                          'Select the color the text is painted with, regardless of what word is written.',
                      context: context,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildRuleRow(
                      icon: Icons.spellcheck_rounded,
                      iconColor: customTheme.accentAmber,
                      title: 'Match Word Text',
                      description:
                          'Select the color spelled by the word, regardless of what ink color is shown.',
                      context: context,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildRuleRow(
                      icon: Icons.sync_problem_rounded,
                      iconColor: AppColors.success,
                      title: 'Watch for RULE SWITCH!',
                      description:
                          'The active rule changes without warning. Switch your mental sorting criteria instantly.',
                      context: context,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Accessible Shapes Legend Card
              AppCard(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Multi-Sensory Options',
                      style: AppTypography.labelLarge.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: MindSwitchColor.values.map((c) {
                        return Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: c
                                    .resolveColor(theme.brightness)
                                    .withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                c.icon,
                                color: c.resolveColor(theme.brightness),
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              c.label,
                              style: AppTypography.labelSmall.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              c.shapeName,
                              style: AppTypography.bodySmall.copyWith(
                                color: customTheme.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Difficulty Selector Card
              AppCard(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Difficulty Tier',
                            style: AppTypography.titleMedium.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        AppChip(
                          label:
                              'Level ${state.difficulty.level} • ${state.difficulty.tierName}',
                          colorType: AppChipColor.violet,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: customTheme.accentViolet,
                        thumbColor: customTheme.accentViolet,
                        inactiveTrackColor:
                            customTheme.accentViolet.withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        key: const Key('mind_switch_difficulty_slider'),
                        value: state.difficulty.level.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: 'Level ${state.difficulty.level}',
                        onChanged: (val) {
                          final selectedDifficulty =
                              GameDifficulty.clamped(val.round());
                          onDifficultyChanged(selectedDifficulty);
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: _buildParamMetric(
                            label: 'Trials',
                            value: '$totalTrials trials',
                            context: context,
                          ),
                        ),
                        Expanded(
                          child: _buildParamMetric(
                            label: 'Time Limit',
                            value: '${timeLimitSec}s / trial',
                            context: context,
                          ),
                        ),
                        Expanded(
                          child: _buildParamMetric(
                            label: 'Mistakes',
                            value: maxMistakes == 0
                                ? 'Strict (0)'
                                : '$maxMistakes allowed',
                            context: context,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Start Game Button
              AppButton(
                key: const Key('start_game_button'),
                label: 'Start Game',
                icon: Icons.play_arrow_rounded,
                isFullWidth: true,
                onPressed: onStartPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final customTheme = context.brainForgeTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTypography.bodySmall.copyWith(
                color: customTheme.textMuted,
              ),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParamMetric({
    required String label,
    required String value,
    required BuildContext context,
  }) {
    final customTheme = context.brainForgeTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: customTheme.textMuted,
          ),
        ),
        Text(
          value,
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
