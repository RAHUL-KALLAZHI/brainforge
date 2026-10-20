import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';
import '../../features/games/shared/data/adaptive_difficulty_repository.dart';
import '../../features/games/shared/data/drift_adaptive_difficulty_repository.dart';
import '../../features/games/shared/data/drift_game_attempt_repository.dart';
import '../../features/games/shared/data/game_attempt_repository.dart';
import '../../features/games/shared/logic/adaptive_difficulty_policy.dart';
import '../../features/games/shared/logic/adaptive_difficulty_service.dart';
import '../../features/games/shared/logic/scoring_service.dart';
import '../../features/progress/logic/progress_cubit.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../features/settings/logic/settings_cubit.dart';

final GetIt getIt = GetIt.instance;

/// Central dependency injection initialization for BrainForge.
Future<void> setupDependencies({
  SharedPreferences? preferences,
  AppDatabase? database,
  GameAttemptRepository? attemptRepository,
  AdaptiveDifficultyRepository? difficultyRepository,
}) async {
  if (getIt.isRegistered<SharedPreferences>()) {
    return;
  }

  // 1. SharedPreferences (allow injecting mock/test instances)
  final prefs = preferences ?? await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  // 2. Database
  final db = database ?? AppDatabase();
  getIt.registerSingleton<AppDatabase>(db);

  // 3. Repositories & Services
  final settingsRepository = SharedPrefsSettingsRepository(prefs);
  getIt.registerSingleton<SettingsRepository>(settingsRepository);

  const scoringService = ScoringService();
  getIt.registerSingleton<ScoringService>(scoringService);

  final repo = attemptRepository ?? DriftGameAttemptRepository(db);
  getIt.registerSingleton<GameAttemptRepository>(repo);

  final diffRepo =
      difficultyRepository ?? DriftAdaptiveDifficultyRepository(db);
  getIt.registerSingleton<AdaptiveDifficultyRepository>(diffRepo);

  const adaptivePolicy = AdaptiveDifficultyPolicy();
  getIt.registerSingleton<AdaptiveDifficultyPolicy>(adaptivePolicy);

  final adaptiveService = AdaptiveDifficultyService(
    attemptRepository: repo,
    difficultyRepository: diffRepo,
    policy: adaptivePolicy,
  );
  getIt.registerSingleton<AdaptiveDifficultyService>(adaptiveService);

  // 4. Application-level Cubits
  getIt.registerLazySingleton<SettingsCubit>(
    () => SettingsCubit(getIt<SettingsRepository>()),
  );

  getIt.registerFactory<ProgressCubit>(
    () => ProgressCubit(
      getIt<GameAttemptRepository>(),
      difficultyRepository: getIt<AdaptiveDifficultyRepository>(),
    ),
  );
}

/// Reset dependencies between unit/widget test runs.
Future<void> resetDependencies() async {
  if (getIt.isRegistered<AppDatabase>()) {
    await getIt<AppDatabase>().close();
  }
  await getIt.reset();
}
