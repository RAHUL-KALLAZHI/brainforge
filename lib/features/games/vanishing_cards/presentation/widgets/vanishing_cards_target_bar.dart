import 'package:flutter/material.dart';
import 'package:brainforge/core/constants/app_spacing.dart';
import 'package:brainforge/core/constants/app_typography.dart';
import 'package:brainforge/core/theme/theme_extensions.dart';
import 'package:brainforge/core/widgets/app_card.dart';
import '../../logic/vanishing_cards_state.dart';

/// Target indicator bar showing active preview instructions or the card to locate.
class VanishingCardsTargetBar extends StatelessWidget {
  final VanishingCardsState state;

  const VanishingCardsTargetBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customTheme = context.brainForgeTheme;

    if (state.isPreviewing) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: customTheme.accentViolet.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.visibility_rounded,
                  color: customTheme.accentViolet,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preview Phase',
                      style: AppTypography.labelMedium.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Memorize the position of each card before they vanish.',
                      style: AppTypography.bodySmall.copyWith(
                        color: customTheme.textMuted,
                        fontSize: 11,
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

    if (state.isInputAllowed && state.currentTargetCard != null) {
      final target = state.currentTargetCard!;
      final currentNum = state.currentTargetStepIndex + 1;
      final totalNum = state.cardsToRecallCount;

      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              // Target card preview chip
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: customTheme.accentViolet.withValues(alpha: 0.18),
                  borderRadius: AppSpacing.roundedSm,
                  border: Border.all(
                    color: customTheme.accentViolet,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  target.symbol.icon,
                  color: customTheme.accentViolet,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Locate: ${target.symbol.label}',
                          style: AppTypography.titleMedium.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Card $currentNum of $totalNum',
                          style: AppTypography.labelSmall.copyWith(
                            color: customTheme.accentViolet,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Tap the card position where the ${target.symbol.label} was located.',
                      style: AppTypography.bodySmall.copyWith(
                        color: customTheme.textMuted,
                        fontSize: 11,
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

    return const SizedBox.shrink();
  }
}
