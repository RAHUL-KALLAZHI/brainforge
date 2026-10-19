import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/games/shared/data/game_attempt_repository.dart';
import '../../features/games/shared/logic/scoring_service.dart';
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

  // 2. Repositories & Services
  final settingsRepository = SharedPrefsSettingsRepository(prefs);
  getIt.registerSingleton<SettingsRepository>(settingsRepository);

  const scoringService = ScoringService();
  getIt.registerSingleton<ScoringService>(scoringService);

  final attemptRepository = InMemoryGameAttemptRepository();
  getIt.registerSingleton<GameAttemptRepository>(attemptRepository);

  // 3. Application-level Cubits
  getIt.registerLazySingleton<SettingsCubit>(
    () => SettingsCubit(getIt<SettingsRepository>()),
  );
}

/// Reset dependencies between unit/widget test runs.
Future<void> resetDependencies() async {
  await getIt.reset();
}
