import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Custom theme extension exposing BrainForge specific brand colors
/// for cards, borders, and multi-color accents.
class BrainForgeThemeExtension
    extends ThemeExtension<BrainForgeThemeExtension> {
  final Color surfaceCard;
  final Color surfaceCardElevated;
  final Color cardBorder;
  final Color accentViolet;
  final Color accentCyan;
  final Color accentAmber;
  final Color textMuted;

  const BrainForgeThemeExtension({
    required this.surfaceCard,
    required this.surfaceCardElevated,
    required this.cardBorder,
    required this.accentViolet,
    required this.accentCyan,
    required this.accentAmber,
    required this.textMuted,
  });

  static const dark = BrainForgeThemeExtension(
    surfaceCard: AppColors.darkSurface,
    surfaceCardElevated: AppColors.darkSurfaceElevated,
    cardBorder: AppColors.darkBorder,
    accentViolet: AppColors.electricViolet,
    accentCyan: AppColors.cyanPulse,
    accentAmber: AppColors.amberReward,
    textMuted: AppColors.darkTextMuted,
  );

  static const light = BrainForgeThemeExtension(
    surfaceCard: AppColors.lightSurface,
    surfaceCardElevated: AppColors.lightSurfaceElevated,
    cardBorder: AppColors.lightBorder,
    accentViolet: AppColors.lightPrimary,
    accentCyan: AppColors.lightSecondary,
    accentAmber: AppColors.amberReward,
    textMuted: AppColors.lightTextMuted,
  );

  @override
  BrainForgeThemeExtension copyWith({
    Color? surfaceCard,
    Color? surfaceCardElevated,
    Color? cardBorder,
    Color? accentViolet,
    Color? accentCyan,
    Color? accentAmber,
    Color? textMuted,
  }) {
    return BrainForgeThemeExtension(
      surfaceCard: surfaceCard ?? this.surfaceCard,
      surfaceCardElevated: surfaceCardElevated ?? this.surfaceCardElevated,
      cardBorder: cardBorder ?? this.cardBorder,
      accentViolet: accentViolet ?? this.accentViolet,
      accentCyan: accentCyan ?? this.accentCyan,
      accentAmber: accentAmber ?? this.accentAmber,
      textMuted: textMuted ?? this.textMuted,
    );
  }

  @override
  ThemeExtension<BrainForgeThemeExtension> lerp(
    covariant ThemeExtension<BrainForgeThemeExtension>? other,
    double t,
  ) {
    if (other is! BrainForgeThemeExtension) return this;
    return BrainForgeThemeExtension(
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      surfaceCardElevated:
          Color.lerp(surfaceCardElevated, other.surfaceCardElevated, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      accentViolet: Color.lerp(accentViolet, other.accentViolet, t)!,
      accentCyan: Color.lerp(accentCyan, other.accentCyan, t)!,
      accentAmber: Color.lerp(accentAmber, other.accentAmber, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
    );
  }
}

extension BrainForgeThemeContext on BuildContext {
  BrainForgeThemeExtension get brainForgeTheme =>
      Theme.of(this).extension<BrainForgeThemeExtension>() ??
      BrainForgeThemeExtension.dark;
}
