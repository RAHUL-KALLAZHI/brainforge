import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../features/settings/logic/settings_cubit.dart';

final GetIt getIt = GetIt.instance;

/// Central dependency injection initialization for BrainForge.
Future<void> setupDependencies({SharedPreferences? preferences}) async {
  if (getIt.isRegistered<SharedPreferences>()) {
    return;
  }

  // 1. SharedPreferences (allow injecting mock/test instances)
  final prefs = preferences ?? await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  // 2. Repositories
  final settingsRepository = SharedPrefsSettingsRepository(prefs);
  getIt.registerSingleton<SettingsRepository>(settingsRepository);

  // 3. Application-level Cubits
  getIt.registerLazySingleton<SettingsCubit>(
    () => SettingsCubit(getIt<SettingsRepository>()),
  );
}

/// Reset dependencies between unit/widget test runs.
Future<void> resetDependencies() async {
  await getIt.reset();
}
