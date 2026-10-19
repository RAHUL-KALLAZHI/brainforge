import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import '../theme/theme_extensions.dart';

enum AppChipColor { defaultColor, violet, cyan, amber, success }

/// Reusable tag/pill chip component for BrainForge.
class AppChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final AppChipColor colorType;

  const AppChip({
    super.key,
    required this.label,
    this.icon,
    this.isSelected = false,
    this.onTap,
    this.colorType = AppChipColor.defaultColor,
  });

  @override
  Widget build(BuildContext context) {
    final customTheme = context.brainForgeTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;
    Color border;

    switch (colorType) {
      case AppChipColor.violet:
        bg = isDark
            ? AppColors.electricViolet
                .withValues(alpha: isSelected ? 0.35 : 0.15)
            : AppColors.lightPrimary.withValues(alpha: isSelected ? 0.25 : 0.1);
        fg = isDark ? AppColors.electricVioletLight : AppColors.lightPrimary;
        border = isDark
            ? AppColors.electricViolet.withValues(alpha: 0.4)
            : AppColors.lightPrimary.withValues(alpha: 0.3);
        break;
      case AppChipColor.cyan:
        bg = isDark
            ? AppColors.cyanPulse.withValues(alpha: isSelected ? 0.35 : 0.15)
            : AppColors.lightSecondary
                .withValues(alpha: isSelected ? 0.25 : 0.1);
        fg = isDark ? AppColors.cyanPulseLight : AppColors.lightSecondary;
        border = isDark
            ? AppColors.cyanPulse.withValues(alpha: 0.4)
            : AppColors.lightSecondary.withValues(alpha: 0.3);
        break;
      case AppChipColor.amber:
        bg = AppColors.amberReward.withValues(alpha: isSelected ? 0.35 : 0.15);
        fg = isDark ? AppColors.amberRewardLight : const Color(0xFFB45309);
        border = AppColors.amberReward.withValues(alpha: 0.4);
        break;
      case AppChipColor.success:
        bg = AppColors.success.withValues(alpha: isSelected ? 0.35 : 0.15);
        fg = isDark ? AppColors.successLight : const Color(0xFF047857);
        border = AppColors.success.withValues(alpha: 0.4);
        break;
      case AppChipColor.defaultColor:
        bg = isSelected
            ? customTheme.cardBorder
            : customTheme.surfaceCardElevated;
        fg = isSelected
            ? Theme.of(context).colorScheme.onSurface
            : customTheme.textMuted;
        border = customTheme.cardBorder;
        break;
    }

    Widget content = Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppSpacing.roundedRound,
        border: Border.all(color: border, width: 1.0),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: AppTypography.labelSmall.copyWith(
                color: fg,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.roundedRound,
        child: content,
      );
    }

    return content;
  }
}
