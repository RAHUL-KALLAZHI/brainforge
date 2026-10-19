import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../core/di/injection.dart';
import '../core/theme/app_theme.dart';
import '../features/settings/logic/settings_cubit.dart';
import '../features/settings/logic/settings_state.dart';
import 'router.dart';

/// Root application widget for BrainForge.
class BrainForgeApp extends StatelessWidget {
  final GoRouter? router;

  const BrainForgeApp({super.key, this.router});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsCubit>.value(
      value: getIt<SettingsCubit>(),
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          return MaterialApp.router(
            title: 'BrainForge',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsState.themeMode,
            routerConfig: router ?? appRouter,
          );
        },
      ),
    );
  }
}
