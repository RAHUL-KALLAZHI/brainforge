import 'package:flutter/material.dart';
import 'package:brainforge/core/constants/app_spacing.dart';
import 'package:brainforge/core/constants/app_typography.dart';
import '../../domain/color_echo_config.dart';

/// Single interactive colored pad widget for Color Echo.
class ColorEchoPad extends StatelessWidget {
  final ColorPadData data;
  final bool isIlluminated;
  final bool isInputAllowed;
  final VoidCallback? onTap;

  const ColorEchoPad({
    super.key,
    required this.data,
    required this.isIlluminated,
    required this.isInputAllowed,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentColor = isIlluminated ? data.activeColor : data.baseColor;

    return Semantics(
      label: data.semanticLabel,
      button: true,
      enabled: isInputAllowed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: currentColor,
          borderRadius: AppSpacing.roundedXl,
          border: Border.all(
            color: isIlluminated
                ? Colors.white
                : data.activeColor.withValues(alpha: 0.4),
            width: isIlluminated ? 3.5 : 1.5,
          ),
          boxShadow: isIlluminated
              ? [
                  BoxShadow(
                    color: data.activeColor.withValues(alpha: 0.6),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: Key('color_echo_pad_${data.index}'),
            borderRadius: AppSpacing.roundedXl,
            onTap: isInputAllowed ? onTap : null,
            splashColor: data.activeColor.withValues(alpha: 0.4),
            highlightColor: data.activeColor.withValues(alpha: 0.2),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    scale: isIlluminated ? 1.25 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      data.icon,
                      size: 40,
                      color: isIlluminated ? Colors.white : Colors.white70,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    data.name,
                    style: AppTypography.titleMedium.copyWith(
                      color: isIlluminated ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
