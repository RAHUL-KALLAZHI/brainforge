import 'package:flutter/material.dart';
import 'package:brainforge/core/constants/app_colors.dart';
import 'package:brainforge/core/constants/app_spacing.dart';
import 'package:brainforge/core/constants/app_typography.dart';
import 'package:brainforge/core/theme/theme_extensions.dart';
import 'package:brainforge/features/games/reverse_recall/logic/reverse_recall_state.dart';

/// Interactive board rendering the reverse entry slots and numeric keypad for Reverse Recall.
class ReverseRecallBoard extends StatelessWidget {
  final ReverseRecallState state;
  final ValueChanged<int> onDigitTapped;

  const ReverseRecallBoard({
    super.key,
    required this.state,
    required this.onDigitTapped,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customTheme = context.brainForgeTheme;

    final targetLength = state.targetSequenceLength;
    final entries = state.playerEntries;
    final currentIndex = state.currentStepIndex;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reverse Instructions Banner
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: customTheme.accentCyan.withValues(alpha: 0.12),
                  borderRadius: AppSpacing.roundedSm,
                  border: Border.all(
                    color: customTheme.accentCyan.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.swap_horiz_rounded,
                      color: customTheme.accentCyan,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'RECALL IN REVERSE ORDER',
                      style: AppTypography.labelSmall.copyWith(
                        color: customTheme.accentCyan,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Enter the digits backwards (last presented digit first)',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: customTheme.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Entered Digits Slot Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(targetLength, (index) {
                    final hasValue = index < entries.length;
                    final isCurrent = index == currentIndex;
                    final isError =
                        isCurrent && state.lastInputCorrect == false;

                    final borderColor = isError
                        ? AppColors.error
                        : (isCurrent
                            ? customTheme.accentCyan
                            : (hasValue
                                ? customTheme.accentCyan.withValues(alpha: 0.6)
                                : customTheme.surfaceCardElevated));

                    final bgColor = hasValue
                        ? customTheme.accentCyan.withValues(alpha: 0.12)
                        : (isCurrent
                            ? customTheme.surfaceCard
                            : customTheme.surfaceCardElevated);

                    return Container(
                      key: ValueKey('slot_$index'),
                      width: 40,
                      height: 48,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: AppSpacing.roundedSm,
                        border: Border.all(
                          color: borderColor,
                          width: isCurrent ? 2.0 : 1.0,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        hasValue
                            ? '${entries[index]}'
                            : (isCurrent ? '?' : '•'),
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: hasValue
                              ? customTheme.accentCyan
                              : (isCurrent
                                  ? theme.colorScheme.onSurface
                                  : customTheme.textMuted),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Numeric Keypad (3x3 grid of digits 1 to 9)
              _buildKeypad(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad(BuildContext context) {
    const rows = [
      [1, 2, 3],
      [4, 5, 6],
      [7, 8, 9],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((digit) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: _buildKeypadButton(context, digit),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeypadButton(BuildContext context, int digit) {
    final theme = Theme.of(context);
    final customTheme = context.brainForgeTheme;

    final isLastTapped = state.lastEnteredDigit == digit;
    final isError = isLastTapped && state.lastInputCorrect == false;

    final buttonColor = isError
        ? AppColors.error.withValues(alpha: 0.2)
        : (isLastTapped && state.lastInputCorrect == true
            ? customTheme.accentCyan.withValues(alpha: 0.25)
            : customTheme.surfaceCard);

    final borderColor = isError
        ? AppColors.error
        : (isLastTapped && state.lastInputCorrect == true
            ? customTheme.accentCyan
            : customTheme.surfaceCardElevated);

    return Semantics(
      button: true,
      label: 'Digit $digit',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('reverse_recall_key_$digit'),
          borderRadius: AppSpacing.roundedMd,
          onTap: state.isInputAllowed ? () => onDigitTapped(digit) : null,
          child: Ink(
            width: 84,
            height: 64,
            decoration: BoxDecoration(
              color: buttonColor,
              borderRadius: AppSpacing.roundedMd,
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$digit',
                style: AppTypography.headlineLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isError
                      ? AppColors.error
                      : (isLastTapped && state.lastInputCorrect == true
                          ? customTheme.accentCyan
                          : theme.colorScheme.onSurface),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
