import 'package:flutter/material.dart';
import 'package:brainforge/core/constants/app_colors.dart';
import 'package:brainforge/core/constants/app_spacing.dart';
import 'package:brainforge/core/constants/app_typography.dart';
import 'package:brainforge/core/theme/theme_extensions.dart';
import '../../domain/vanishing_cards_config.dart';

/// Interactive card tile widget representing an individual position on the board.
class VanishingCardsTile extends StatelessWidget {
  final VanishingCard card;
  final bool isPreviewing;
  final bool isFound;
  final bool isMistake;
  final bool isInteractive;
  final VoidCallback onTap;

  const VanishingCardsTile({
    super.key,
    required this.card,
    required this.isPreviewing,
    required this.isFound,
    required this.isMistake,
    required this.isInteractive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final customTheme = context.brainForgeTheme;
    final theme = Theme.of(context);

    // Determine visual style
    final bool isFaceUp = isPreviewing || isFound || isMistake;

    final Color cardBackground;
    final Color borderColor;
    final double borderWidth;

    if (isFound) {
      cardBackground = customTheme.accentViolet.withValues(alpha: 0.18);
      borderColor = customTheme.accentCyan;
      borderWidth = 2.0;
    } else if (isMistake) {
      cardBackground = AppColors.error.withValues(alpha: 0.18);
      borderColor = AppColors.error;
      borderWidth = 2.0;
    } else if (isPreviewing) {
      cardBackground = customTheme.surfaceCard;
      borderColor = customTheme.accentViolet.withValues(alpha: 0.6);
      borderWidth = 1.5;
    } else {
      // Concealed card back
      cardBackground = customTheme.surfaceCardElevated;
      borderColor = customTheme.cardBorder;
      borderWidth = 1.0;
    }

    String semanticLabel;
    if (isFound) {
      semanticLabel = '${card.symbol.label} card, correctly recalled';
    } else if (isMistake) {
      semanticLabel = '${card.symbol.label} card, incorrect selection';
    } else if (isPreviewing) {
      semanticLabel =
          '${card.symbol.label} card at position ${card.positionIndex + 1}';
    } else {
      semanticLabel = 'Concealed card, position ${card.positionIndex + 1}';
    }

    return Semantics(
      label: semanticLabel,
      button: isInteractive && !isFaceUp,
      enabled: isInteractive && !isFaceUp,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('vanishing_card_tile_${card.positionIndex}'),
          onTap: (isInteractive && !isFound && !isMistake) ? onTap : null,
          borderRadius: AppSpacing.roundedMd,
          splashColor: customTheme.accentViolet.withValues(alpha: 0.25),
          highlightColor: customTheme.accentViolet.withValues(alpha: 0.15),
          child: Container(
            constraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: AppSpacing.roundedMd,
              border: Border.all(
                color: borderColor,
                width: borderWidth,
              ),
              boxShadow: isFaceUp
                  ? [
                      BoxShadow(
                        color: (isFound
                                ? customTheme.accentCyan
                                : isMistake
                                    ? AppColors.error
                                    : customTheme.accentViolet)
                            .withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Card face content
                if (isFaceUp) ...[
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          card.symbol.icon,
                          color: isFound
                              ? customTheme.accentCyan
                              : isMistake
                                  ? AppColors.error
                                  : customTheme.accentViolet,
                          size: 32,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          card.symbol.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelSmall.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Card back design
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.style_rounded,
                          color:
                              customTheme.accentViolet.withValues(alpha: 0.35),
                          size: 26,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${card.positionIndex + 1}',
                          style: AppTypography.bodySmall.copyWith(
                            color: customTheme.textMuted.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Success badge
                if (isFound)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: customTheme.accentCyan,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.black,
                        size: 12,
                      ),
                    ),
                  ),

                // Error badge
                if (isMistake)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
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
