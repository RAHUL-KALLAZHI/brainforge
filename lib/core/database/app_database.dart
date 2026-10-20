import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables/game_attempts_table.dart';
import 'tables/player_game_profiles_table.dart';

part 'app_database.g.dart';

/// Central SQLite application database powered by Drift.
///
/// Manages schema versions, connection lifecycle, and local data persistence.
@DriftDatabase(tables: [GameAttempts, PlayerGameProfiles])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(playerGameProfiles);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'brainforge');
  }
}
