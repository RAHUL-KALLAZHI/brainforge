import 'package:flutter/material.dart';
import 'package:brainforge/core/constants/app_colors.dart';
import 'package:brainforge/core/constants/app_spacing.dart';
import 'package:brainforge/core/constants/app_typography.dart';
import 'package:brainforge/core/theme/theme_extensions.dart';
import 'package:brainforge/features/games/mind_switch/domain/mind_switch_challenge.dart';
import 'package:brainforge/features/games/mind_switch/logic/mind_switch_state.dart';

/// Interactive board presenting the center Stroop stimulus and 4 multi-sensory options.
class MindSwitchBoard extends StatelessWidget {
  final MindSwitchState state;
  final ValueChanged<MindSwitchColor> onColorSelected;

  const MindSwitchBoard({
    super.key,
    required this.state,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final customTheme = context.brainForgeTheme;
    final trial = state.currentTrial;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        children: [
          // Center Stimulus / Countdown / Switch Alert Card
          Expanded(
            flex: 4,
            child: Center(
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 420, maxHeight: 180),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: customTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: state.lastInputCorrect == true
                          ? AppColors.success.withValues(alpha: 0.8)
                          : (state.lastInputCorrect == false
                              ? AppColors.error.withValues(alpha: 0.8)
                              : customTheme.cardBorder),
                      width: state.lastInputCorrect != null ? 2.5 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _buildStimulusContent(context, trial),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 2x2 Multi-sensory Options Grid
          Expanded(
            flex: 5,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.6,
                physics: const NeverScrollableScrollPhysics(),
                children: MindSwitchColor.values.map((color) {
                  return _buildOptionButton(
                    context: context,
                    color: color,
                    isEnabled: state.isInputAllowed,
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStimulusContent(BuildContext context, MindSwitchTrial? trial) {
    final theme = Theme.of(context);
    final customTheme = context.brainForgeTheme;

    // 1. Pre-game countdown display
    if (state.isCountingDown) {
      final seconds = state.sessionState.countdownSecondsRemaining;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$seconds',
            style: AppTypography.displayLarge.copyWith(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: AppColors.amberReward,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Get Ready...',
            style: AppTypography.titleMedium.copyWith(
              color: customTheme.textMuted,
            ),
          ),
        ],
      );
    }

    // 2. Rule switch alert banner
    if (state.showRuleSwitchBanner) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: customTheme.accentViolet.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: customTheme.accentViolet,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sync_problem_rounded,
              color: customTheme.accentViolet,
              size: 40,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'RULE SWITCH!',
              style: AppTypography.titleLarge.copyWith(
                color: customTheme.accentViolet,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'NOW: ${state.currentRule.shortLabel}',
              style: AppTypography.labelLarge.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // 3. Active Stroop word stimulus
    if (trial != null) {
      final inkColor = trial.inkColor.resolveColor(theme.brightness);

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            trial.wordColor.label.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w900,
              color: inkColor,
              letterSpacing: 3.0,
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildOptionButton({
    required BuildContext context,
    required MindSwitchColor color,
    required bool isEnabled,
  }) {
    final theme = Theme.of(context);
    final customTheme = context.brainForgeTheme;
    final resolvedColor = color.resolveColor(theme.brightness);

    final isSelected = state.lastSelectedColor == color;
    final isCorrect = isSelected && state.lastInputCorrect == true;
    final isWrong = isSelected && state.lastInputCorrect == false;

    Color borderColor = resolvedColor.withValues(alpha: 0.5);
    Color backgroundColor = resolvedColor.withValues(alpha: 0.1);

    if (isCorrect) {
      borderColor = AppColors.success;
      backgroundColor = AppColors.success.withValues(alpha: 0.25);
    } else if (isWrong) {
      borderColor = AppColors.error;
      backgroundColor = AppColors.error.withValues(alpha: 0.25);
    }

    return Semantics(
      label: color.semanticLabel,
      button: true,
      enabled: isEnabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('mind_switch_color_button_${color.name}'),
          onTap: isEnabled ? () => onColorSelected(color) : null,
          borderRadius: BorderRadius.circular(16),
          splashColor: resolvedColor.withValues(alpha: 0.3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              vertical: 6,
              horizontal: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 2.5 : 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  color.icon,
                  color: resolvedColor,
                  size: 26,
                ),
                const SizedBox(height: 2),
                Text(
                  color.label,
                  style: AppTypography.titleMedium.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  color.shapeName,
                  style: AppTypography.bodySmall.copyWith(
                    color: customTheme.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
