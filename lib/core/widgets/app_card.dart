import 'package:flutter/material.dart';
import '../constants/app_spacing.dart';
import '../theme/theme_extensions.dart';

/// Reusable elevated card container matching BrainForge aesthetic.
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  final Gradient? gradient;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = AppSpacing.cardPadding,
    this.margin = EdgeInsets.zero,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final customTheme = context.brainForgeTheme;
    final radius = borderRadius ?? AppSpacing.roundedLg;
    final effectiveBg = backgroundColor ?? customTheme.surfaceCard;
    final effectiveBorder = borderColor ?? customTheme.cardBorder;

    Widget content;

    if (gradient != null) {
      content = Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: radius,
          border: Border.all(color: effectiveBorder, width: 1.0),
        ),
        padding: padding,
        child: child,
      );
      if (onTap != null) {
        content = Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: content,
          ),
        );
      }
    } else {
      content = Material(
        color: effectiveBg,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: effectiveBorder, width: 1.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      );
    }

    if (margin != EdgeInsets.zero) {
      return Padding(padding: margin, child: content);
    }

    return content;
  }
}
