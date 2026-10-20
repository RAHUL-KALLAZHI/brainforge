import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_keys.dart';
import '../features/games/color_echo/presentation/color_echo_screen.dart';
import '../features/games/focus_hunter/presentation/focus_hunter_screen.dart';
import '../features/games/memory_grid/presentation/memory_grid_screen.dart';
import '../features/games/vanishing_cards/presentation/vanishing_cards_screen.dart';
import '../features/games/presentation/games_catalog_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/navigation/navigation_shell.dart';
import '../features/navigation/not_found_screen.dart';
import '../features/progress/presentation/progress_dashboard_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/workouts/presentation/daily_workout_intro_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'rootNav');

/// Central GoRouter configuration for BrainForge.
final GoRouter appRouter = createRouter();

/// Factory function to create [GoRouter] instances for production and testing.
GoRouter createRouter({
  String initialLocation = AppKeys.homePath,
  List<NavigatorObserver>? observers,
}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: initialLocation,
    observers: observers,
    errorBuilder: (context, state) => NotFoundScreen(uri: state.uri.toString()),
    routes: [
      // Root redirect
      GoRoute(
        path: '/',
        redirect: (_, __) => AppKeys.homePath,
      ),

      // Fullscreen Memory Grid game session
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppKeys.memoryGridPath,
        builder: (context, state) => const MemoryGridScreen(),
      ),

      // Fullscreen Color Echo game session
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppKeys.colorEchoPath,
        builder: (context, state) => const ColorEchoScreen(),
      ),

      // Fullscreen Focus Hunter game session
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppKeys.focusHunterPath,
        builder: (context, state) => const FocusHunterScreen(),
      ),

      // Fullscreen Vanishing Cards game session
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppKeys.vanishingCardsPath,
        builder: (context, state) => const VanishingCardsScreen(),
      ),

      // StatefulShellRoute preserving branch states across tabs
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return NavigationShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppKeys.homePath,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomeScreen(),
                ),
              ),
            ],
          ),

          // Branch 1: Games
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppKeys.gamesPath,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: GamesCatalogScreen(),
                ),
              ),
            ],
          ),

          // Branch 2: Daily Workout
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppKeys.workoutPath,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: DailyWorkoutIntroScreen(),
                ),
              ),
            ],
          ),

          // Branch 3: Progress
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppKeys.progressPath,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ProgressDashboardScreen(),
                ),
              ),
            ],
          ),

          // Branch 4: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppKeys.settingsPath,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: SettingsScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
