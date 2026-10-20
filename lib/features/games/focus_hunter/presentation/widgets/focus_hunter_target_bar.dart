import 'package:flutter/material.dart';
import 'package:brainforge/core/constants/app_spacing.dart';
import 'package:brainforge/core/constants/app_typography.dart';
import 'package:brainforge/core/theme/theme_extensions.dart';
import 'package:brainforge/features/games/focus_hunter/logic/focus_hunter_state.dart';

/// Prominently displays the designated target symbol and color for the active round.
class FocusHunterTargetBar extends StatelessWidget {
  final FocusHunterState state;

  const FocusHunterTargetBar({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customTheme = context.brainForgeTheme;
    final targetSymbol = state.challenge.targetSymbol;
    final targetColor = state.challenge.targetColor;
    final resolvedColor = targetColor.resolveColor(theme.brightness);

    final semanticLabel =
        'Target item: ${targetColor.label} ${targetSymbol.label}, ${targetSymbol.semanticDescription}. ${state.targetsRemaining} remaining to find.';

    return Semantics(
      label: semanticLabel,
      container: true,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: customTheme.surfaceCard,
          borderRadius: AppSpacing.roundedMd,
          border: Border.all(
            color: resolvedColor.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: resolvedColor.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: resolvedColor.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: resolvedColor.withValues(alpha: 0.6),
                  width: 1.5,
                ),
              ),
              child: Icon(
                targetSymbol.icon,
                color: resolvedColor,
                size: 26,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FIND TARGET',
                    style: AppTypography.labelSmall.copyWith(
                      color: customTheme.textMuted,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${targetColor.label} ${targetSymbol.label}',
                        style: AppTypography.titleMedium.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: resolvedColor.withValues(alpha: 0.12),
                borderRadius: AppSpacing.roundedSm,
              ),
              child: Text(
                '${state.targetsRemaining} LEFT',
                style: AppTypography.labelSmall.copyWith(
                  color: resolvedColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
