import 'package:brainforge/core/constants/app_colors.dart';
import 'package:brainforge/core/theme/app_theme.dart';
import 'package:brainforge/core/theme/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme Unit Tests', () {
    test('dark theme matches BrainForge specifications', () {
      final dark = AppTheme.darkTheme;
      expect(dark.brightness, equals(Brightness.dark));
      expect(dark.scaffoldBackgroundColor, equals(AppColors.darkBackground));
      expect(dark.colorScheme.primary, equals(AppColors.electricViolet));
      expect(dark.colorScheme.secondary, equals(AppColors.cyanPulse));
      expect(dark.colorScheme.surface, equals(AppColors.darkSurface));

      final extension = dark.extension<BrainForgeThemeExtension>();
      expect(extension, isNotNull);
      expect(extension!.surfaceCard, equals(AppColors.darkSurface));
      expect(extension.cardBorder, equals(AppColors.darkBorder));
      expect(extension.accentViolet, equals(AppColors.electricViolet));
      expect(extension.accentCyan, equals(AppColors.cyanPulse));
    });

    test('light theme matches BrainForge specifications', () {
      final light = AppTheme.lightTheme;
      expect(light.brightness, equals(Brightness.light));
      expect(light.scaffoldBackgroundColor, equals(AppColors.lightBackground));
      expect(light.colorScheme.primary, equals(AppColors.lightPrimary));
      expect(light.colorScheme.secondary, equals(AppColors.lightSecondary));

      final extension = light.extension<BrainForgeThemeExtension>();
      expect(extension, isNotNull);
      expect(extension!.surfaceCard, equals(AppColors.lightSurface));
      expect(extension.cardBorder, equals(AppColors.lightBorder));
      expect(extension.accentViolet, equals(AppColors.lightPrimary));
    });

    test('BrainForgeThemeExtension copyWith and lerp operate correctly', () {
      const ext = BrainForgeThemeExtension.dark;
      final copied = ext.copyWith(surfaceCard: Colors.red);
      expect(copied.surfaceCard, equals(Colors.red));
      expect(copied.accentViolet, equals(ext.accentViolet));

      final lerped = ext.lerp(BrainForgeThemeExtension.light, 0.5)
          as BrainForgeThemeExtension;
      expect(lerped, isNotNull);
      expect(lerped.accentViolet, isNot(equals(ext.accentViolet)));
    });
  });
}
