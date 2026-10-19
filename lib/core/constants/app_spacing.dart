import 'package:flutter/material.dart';

/// Centralized spacing and border radius metrics for BrainForge.
abstract final class AppSpacing {
  // Spacing scales
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 48.0;

  // Insets
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets compactCardPadding = EdgeInsets.all(md);
  static const EdgeInsets modalPadding = EdgeInsets.all(xxl);

  // Border Radii
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusRound = 999.0;

  static const BorderRadius roundedXs =
      BorderRadius.all(Radius.circular(radiusXs));
  static const BorderRadius roundedSm =
      BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius roundedMd =
      BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius roundedLg =
      BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius roundedXl =
      BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius roundedRound =
      BorderRadius.all(Radius.circular(radiusRound));
}
