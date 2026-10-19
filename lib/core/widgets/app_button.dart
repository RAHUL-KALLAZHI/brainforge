import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import 'loading_indicator.dart';

enum AppButtonVariant { primary, secondary, outline, ghost }

/// Accessible, styled button component for BrainForge.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEnabled = onPressed != null && !isLoading;

    // Styling per variant
    Color backgroundColor;
    Color foregroundColor;
    BorderSide? borderSide;

    switch (variant) {
      case AppButtonVariant.primary:
        backgroundColor = isEnabled
            ? (isDark ? AppColors.electricViolet : AppColors.lightPrimary)
            : (isDark ? const Color(0xFF2E2A4A) : const Color(0xFFE2E8F0));
        foregroundColor = isEnabled
            ? Colors.white
            : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted);
        break;
      case AppButtonVariant.secondary:
        backgroundColor = isEnabled
            ? (isDark ? const Color(0xFF164E63) : const Color(0xFFE0F2FE))
            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9));
        foregroundColor = isEnabled
            ? (isDark ? AppColors.cyanPulse : AppColors.lightSecondary)
            : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted);
        break;
      case AppButtonVariant.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = isEnabled
            ? (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)
            : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted);
        borderSide = BorderSide(
          color: isEnabled
              ? (isDark ? AppColors.darkBorderLight : AppColors.lightBorderDark)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: 1.5,
        );
        break;
      case AppButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = isEnabled
            ? (isDark ? AppColors.cyanPulse : AppColors.lightPrimary)
            : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted);
        break;
    }

    Widget content;
    if (isLoading) {
      content = SizedBox(
        height: 20,
        width: 20,
        child: LoadingIndicator(
          size: 20,
          color: foregroundColor,
          strokeWidth: 2.2,
        ),
      );
    } else {
      content = Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: foregroundColor),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            label,
            style: AppTypography.labelLarge.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    final button = Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.roundedMd,
        side: borderSide ?? BorderSide.none,
      ),
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: AppSpacing.roundedMd,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 64),
          child: Padding(
            padding: padding ??
                const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
            child: Center(
              widthFactor: isFullWidth ? null : 1.0,
              child: content,
            ),
          ),
        ),
      ),
    );

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
