import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_keys.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';

/// Fallback screen for unknown routes and broken deep links.
class NotFoundScreen extends StatelessWidget {
  final String? uri;

  const NotFoundScreen({super.key, this.uri});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customTheme = context.brainForgeTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: AppCard(
              padding: AppSpacing.cardPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: customTheme.accentViolet.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.explore_off_rounded,
                      color: customTheme.accentViolet,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Page Not Found',
                    style: AppTypography.displayMedium.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    uri != null
                        ? 'The destination "$uri" does not exist or has moved.'
                        : 'The requested screen could not be located.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: customTheme.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: 'Return to Home',
                    icon: Icons.home_rounded,
                    variant: AppButtonVariant.primary,
                    isFullWidth: true,
                    onPressed: () => context.go(AppKeys.homePath),
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
