import 'package:flutter/material.dart';
import 'package:brainforge/core/constants/app_spacing.dart';
import 'package:brainforge/core/constants/app_typography.dart';
import 'package:brainforge/core/theme/theme_extensions.dart';
import '../../domain/color_echo_config.dart';
import '../../logic/color_echo_state.dart';
import 'color_echo_pad.dart';

/// Interactive board rendering the 2x2 grid of color pads in Color Echo.
class ColorEchoBoard extends StatelessWidget {
  final ColorEchoState state;
  final ValueChanged<int> onPadTapped;

  const ColorEchoBoard({
    super.key,
    required this.state,
    required this.onPadTapped,
  });

  @override
  Widget build(BuildContext context) {
    final customTheme = context.brainForgeTheme;
    const pads = ColorEchoConfig.pads;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 380),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sequence Step Progress
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: state.isInputAllowed ? 1.0 : 0.0,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: customTheme.surfaceCard,
                      borderRadius: AppSpacing.roundedRound,
                      border: Border.all(
                        color: customTheme.accentCyan.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'Input: ${state.currentStepIndex} / ${state.targetSequenceLength}',
                      key: const Key('color_echo_step_progress'),
                      style: AppTypography.labelMedium.copyWith(
                        color: customTheme.accentCyan,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // 2x2 Quadrant Board
              Flexible(
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    children: pads.map((pad) {
                      final isIlluminated =
                          state.activePreviewPadIndex == pad.index ||
                              (state.isInputAllowed &&
                                  state.lastTappedPad == pad.index &&
                                  (state.lastInputCorrect ?? false));

                      return ColorEchoPad(
                        key: ValueKey('pad_${pad.index}'),
                        data: pad,
                        isIlluminated: isIlluminated,
                        isInputAllowed: state.isInputAllowed,
                        onTap: () => onPadTapped(pad.index),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
