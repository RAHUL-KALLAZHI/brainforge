import 'package:flutter/material.dart';

/// Centralized color palette for BrainForge.
///
/// Features deep indigo/navy backgrounds, electric purple & cyan highlights,
/// and restrained gold/amber accents for rewards.
abstract final class AppColors {
  // Brand tokens specified in product requirements
  static const Color deepSpaceNavy = Color(0xFF0B0E17);
  static const Color surfaceCardDark = Color(0xFF141926);
  static const Color surfaceCardDarkElevated = Color(0xFF1A2133);
  static const Color electricViolet = Color(0xFF7C3AED);
  static const Color electricVioletLight = Color(0xFF9061F9);
  static const Color cyanPulse = Color(0xFF06B6D4);
  static const Color cyanPulseLight = Color(0xFF22D3EE);
  static const Color amberReward = Color(0xFFF59E0B);
  static const Color amberRewardLight = Color(0xFFFBBF24);

  // Status & semantic colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Dark Theme surface & text tokens
  static const Color darkBackground = deepSpaceNavy;
  static const Color darkSurface = surfaceCardDark;
  static const Color darkSurfaceElevated = surfaceCardDarkElevated;
  static const Color darkBorder = Color(0xFF222B40);
  static const Color darkBorderLight = Color(0xFF2E3A57);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Light Theme surface & text tokens
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightBorderDark = Color(0xFFCBD5E1);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // Light Theme brand variants for WCAG AA contrast against white/light surfaces
  static const Color lightPrimary = Color(0xFF6D28D9);
  static const Color lightSecondary = Color(0xFF0891B2);
}
