import 'package:flutter/material.dart';
import 'package:brainforge/core/constants/app_colors.dart';
import 'package:brainforge/core/constants/app_spacing.dart';
import 'package:brainforge/core/theme/theme_extensions.dart';
import 'package:brainforge/features/games/focus_hunter/domain/focus_hunter_config.dart';

/// Interactive tile displaying a visual symbol and color on the Focus Hunter board.
class FocusHunterTile extends StatelessWidget {
  final FocusHunterItem item;
  final int index;
  final bool isFoundTarget;
  final bool isMistake;
  final bool isInputAllowed;
  final VoidCallback onTap;

  const FocusHunterTile({
    super.key,
    required this.item,
    required this.index,
    required this.isFoundTarget,
    required this.isMistake,
    required this.isInputAllowed,
    required this.onTap,
  });

  bool get isSelected => isFoundTarget || isMistake;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customTheme = context.brainForgeTheme;
    final itemColor = item.color.resolveColor(theme.brightness);

    final semanticStatus = isFoundTarget
        ? 'Target found'
        : isMistake
            ? 'Incorrect selection'
            : 'Unselected';

    final semanticLabel =
        '${item.color.label} ${item.symbol.label}, ${item.symbol.semanticDescription}. $semanticStatus';

    Color backgroundColor;
    Color borderColor;
    double borderWidth = 1.0;

    if (isFoundTarget) {
      backgroundColor = itemColor.withValues(alpha: 0.25);
      borderColor = itemColor;
      borderWidth = 2.5;
    } else if (isMistake) {
      backgroundColor = AppColors.error.withValues(alpha: 0.2);
      borderColor = AppColors.error;
      borderWidth = 2.0;
    } else {
      backgroundColor = customTheme.surfaceCardElevated;
      borderColor = customTheme.cardBorder;
    }

    return Semantics(
      button: true,
      enabled: isInputAllowed && !isSelected,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (isInputAllowed && !isSelected) ? onTap : null,
          borderRadius: AppSpacing.roundedMd,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: AppSpacing.roundedMd,
              border: Border.all(
                color: borderColor,
                width: borderWidth,
              ),
              boxShadow: isFoundTarget
                  ? [
                      BoxShadow(
                        color: itemColor.withValues(alpha: 0.35),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Base symbol
                Opacity(
                  opacity: isSelected ? 0.6 : 1.0,
                  child: Icon(
                    item.symbol.icon,
                    color: itemColor,
                    size: 32,
                  ),
                ),

                // Success Badge
                if (isFoundTarget)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: itemColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: theme.colorScheme.surface,
                        size: 14,
                      ),
                    ),
                  ),

                // Error Badge
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
                        size: 14,
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
