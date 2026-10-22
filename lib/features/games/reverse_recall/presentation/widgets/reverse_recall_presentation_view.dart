import 'package:flutter/material.dart';
import 'package:brainforge/core/constants/app_spacing.dart';
import 'package:brainforge/core/constants/app_typography.dart';
import 'package:brainforge/core/theme/theme_extensions.dart';
import 'package:brainforge/core/widgets/app_card.dart';
import 'package:brainforge/features/games/reverse_recall/logic/reverse_recall_state.dart';

/// Widget rendering the forward presentation phase of Reverse Recall.
class ReverseRecallPresentationView extends StatelessWidget {
  final ReverseRecallState state;

  const ReverseRecallPresentationView({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customTheme = context.brainForgeTheme;

    final activeDigit = state.activePresentedDigit;
    final currentIndex = state.presentedStepIndex;
    final totalDigits = state.targetSequenceLength;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Presentation Header
              Text(
                'MEMORIZE SEQUENCE',
                style: AppTypography.labelSmall.copyWith(
                  color: customTheme.accentCyan,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Digit ${currentIndex + 1} of $totalDigits',
                style: AppTypography.titleMedium.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Prominent Active Digit Display Card
              AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: AppSpacing.huge,
                ),
                backgroundColor: customTheme.surfaceCard,
                child: SizedBox(
                  height: 160,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: activeDigit != null
                          ? Semantics(
                              label: 'Showing digit $activeDigit',
                              child: Container(
                                key: ValueKey('active_digit_$activeDigit'),
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: customTheme.accentCyan
                                      .withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: customTheme.accentCyan,
                                    width: 3.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: customTheme.accentCyan
                                          .withValues(alpha: 0.4),
                                      blurRadius: 24,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$activeDigit',
                                  style: AppTypography.displayLarge.copyWith(
                                    fontSize: 64,
                                    fontWeight: FontWeight.bold,
                                    color: customTheme.accentCyan,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              key: const ValueKey('gap_indicator'),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: customTheme.surfaceCardElevated,
                                shape: BoxShape.circle,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Progress Indicator
              ClipRRect(
                borderRadius: AppSpacing.roundedSm,
                child: LinearProgressIndicator(
                  value: totalDigits > 0
                      ? ((currentIndex + (activeDigit != null ? 1 : 0)) /
                              totalDigits)
                          .clamp(0.0, 1.0)
                      : 0.0,
                  backgroundColor: customTheme.surfaceCardElevated,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    customTheme.accentCyan,
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Input Locking Label
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_clock_rounded,
                    color: customTheme.textMuted,
                    size: 16,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      'Input locked during presentation',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: customTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
