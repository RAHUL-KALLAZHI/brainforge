// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $GameAttemptsTable extends GameAttempts
    with TableInfo<$GameAttemptsTable, GameAttemptEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GameAttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<String> gameId = GeneratedColumn<String>(
      'game_id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 64),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _difficultyLevelMeta =
      const VerificationMeta('difficultyLevel');
  @override
  late final GeneratedColumn<int> difficultyLevel = GeneratedColumn<int>(
      'difficulty_level', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 32),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _finalScoreMeta =
      const VerificationMeta('finalScore');
  @override
  late final GeneratedColumn<int> finalScore = GeneratedColumn<int>(
      'final_score', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _accuracyMeta =
      const VerificationMeta('accuracy');
  @override
  late final GeneratedColumn<double> accuracy = GeneratedColumn<double>(
      'accuracy', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _correctCountMeta =
      const VerificationMeta('correctCount');
  @override
  late final GeneratedColumn<int> correctCount = GeneratedColumn<int>(
      'correct_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _incorrectCountMeta =
      const VerificationMeta('incorrectCount');
  @override
  late final GeneratedColumn<int> incorrectCount = GeneratedColumn<int>(
      'incorrect_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _missedCountMeta =
      const VerificationMeta('missedCount');
  @override
  late final GeneratedColumn<int> missedCount = GeneratedColumn<int>(
      'missed_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _responseTimesMsMeta =
      const VerificationMeta('responseTimesMs');
  @override
  late final GeneratedColumn<String> responseTimesMs = GeneratedColumn<String>(
      'response_times_ms', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
      'started_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _seedMeta = const VerificationMeta('seed');
  @override
  late final GeneratedColumn<int> seed = GeneratedColumn<int>(
      'seed', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        gameId,
        difficultyLevel,
        status,
        finalScore,
        accuracy,
        correctCount,
        incorrectCount,
        missedCount,
        responseTimesMs,
        startedAt,
        completedAt,
        seed
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'game_attempts';
  @override
  VerificationContext validateIntegrity(Insertable<GameAttemptEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('game_id')) {
      context.handle(_gameIdMeta,
          gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta));
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('difficulty_level')) {
      context.handle(
          _difficultyLevelMeta,
          difficultyLevel.isAcceptableOrUnknown(
              data['difficulty_level']!, _difficultyLevelMeta));
    } else if (isInserting) {
      context.missing(_difficultyLevelMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('final_score')) {
      context.handle(
          _finalScoreMeta,
          finalScore.isAcceptableOrUnknown(
              data['final_score']!, _finalScoreMeta));
    } else if (isInserting) {
      context.missing(_finalScoreMeta);
    }
    if (data.containsKey('accuracy')) {
      context.handle(_accuracyMeta,
          accuracy.isAcceptableOrUnknown(data['accuracy']!, _accuracyMeta));
    } else if (isInserting) {
      context.missing(_accuracyMeta);
    }
    if (data.containsKey('correct_count')) {
      context.handle(
          _correctCountMeta,
          correctCount.isAcceptableOrUnknown(
              data['correct_count']!, _correctCountMeta));
    } else if (isInserting) {
      context.missing(_correctCountMeta);
    }
    if (data.containsKey('incorrect_count')) {
      context.handle(
          _incorrectCountMeta,
          incorrectCount.isAcceptableOrUnknown(
              data['incorrect_count']!, _incorrectCountMeta));
    } else if (isInserting) {
      context.missing(_incorrectCountMeta);
    }
    if (data.containsKey('missed_count')) {
      context.handle(
          _missedCountMeta,
          missedCount.isAcceptableOrUnknown(
              data['missed_count']!, _missedCountMeta));
    } else if (isInserting) {
      context.missing(_missedCountMeta);
    }
    if (data.containsKey('response_times_ms')) {
      context.handle(
          _responseTimesMsMeta,
          responseTimesMs.isAcceptableOrUnknown(
              data['response_times_ms']!, _responseTimesMsMeta));
    } else if (isInserting) {
      context.missing(_responseTimesMsMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('seed')) {
      context.handle(
          _seedMeta, seed.isAcceptableOrUnknown(data['seed']!, _seedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GameAttemptEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GameAttemptEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      gameId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}game_id'])!,
      difficultyLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}difficulty_level'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      finalScore: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}final_score'])!,
      accuracy: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}accuracy'])!,
      correctCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}correct_count'])!,
      incorrectCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}incorrect_count'])!,
      missedCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}missed_count'])!,
      responseTimesMs: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}response_times_ms'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}started_at'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at'])!,
      seed: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}seed']),
    );
  }

  @override
  $GameAttemptsTable createAlias(String alias) {
    return $GameAttemptsTable(attachedDatabase, alias);
  }
}

class GameAttemptEntry extends DataClass
    implements Insertable<GameAttemptEntry> {
  /// Unique attempt identifier (e.g., 'mg_1730000000000_42').
  final String id;

  /// Identifier of the game (e.g., 'memory_grid').
  final String gameId;

  /// Difficulty level (1 to 5).
  final int difficultyLevel;

  /// Completion status (e.g., 'completed', 'failed', 'abandoned', 'timeout').
  final String status;

  /// Final computed score.
  final int finalScore;

  /// Accuracy ratio (0.0 to 1.0).
  final double accuracy;

  /// Count of correct inputs.
  final int correctCount;

  /// Count of incorrect inputs.
  final int incorrectCount;

  /// Count of missed targets / inputs.
  final int missedCount;

  /// JSON-encoded array of response latency measurements in milliseconds.
  final String responseTimesMs;

  /// Timestamp when the game session started (stored in UTC).
  final DateTime startedAt;

  /// Timestamp when the game session completed or terminated (stored in UTC).
  final DateTime completedAt;

  /// Deterministic generation seed, if specified.
  final int? seed;
  const GameAttemptEntry(
      {required this.id,
      required this.gameId,
      required this.difficultyLevel,
      required this.status,
      required this.finalScore,
      required this.accuracy,
      required this.correctCount,
      required this.incorrectCount,
      required this.missedCount,
      required this.responseTimesMs,
      required this.startedAt,
      required this.completedAt,
      this.seed});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['game_id'] = Variable<String>(gameId);
    map['difficulty_level'] = Variable<int>(difficultyLevel);
    map['status'] = Variable<String>(status);
    map['final_score'] = Variable<int>(finalScore);
    map['accuracy'] = Variable<double>(accuracy);
    map['correct_count'] = Variable<int>(correctCount);
    map['incorrect_count'] = Variable<int>(incorrectCount);
    map['missed_count'] = Variable<int>(missedCount);
    map['response_times_ms'] = Variable<String>(responseTimesMs);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['completed_at'] = Variable<DateTime>(completedAt);
    if (!nullToAbsent || seed != null) {
      map['seed'] = Variable<int>(seed);
    }
    return map;
  }

  GameAttemptsCompanion toCompanion(bool nullToAbsent) {
    return GameAttemptsCompanion(
      id: Value(id),
      gameId: Value(gameId),
      difficultyLevel: Value(difficultyLevel),
      status: Value(status),
      finalScore: Value(finalScore),
      accuracy: Value(accuracy),
      correctCount: Value(correctCount),
      incorrectCount: Value(incorrectCount),
      missedCount: Value(missedCount),
      responseTimesMs: Value(responseTimesMs),
      startedAt: Value(startedAt),
      completedAt: Value(completedAt),
      seed: seed == null && nullToAbsent ? const Value.absent() : Value(seed),
    );
  }

  factory GameAttemptEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GameAttemptEntry(
      id: serializer.fromJson<String>(json['id']),
      gameId: serializer.fromJson<String>(json['gameId']),
      difficultyLevel: serializer.fromJson<int>(json['difficultyLevel']),
      status: serializer.fromJson<String>(json['status']),
      finalScore: serializer.fromJson<int>(json['finalScore']),
      accuracy: serializer.fromJson<double>(json['accuracy']),
      correctCount: serializer.fromJson<int>(json['correctCount']),
      incorrectCount: serializer.fromJson<int>(json['incorrectCount']),
      missedCount: serializer.fromJson<int>(json['missedCount']),
      responseTimesMs: serializer.fromJson<String>(json['responseTimesMs']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      seed: serializer.fromJson<int?>(json['seed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'gameId': serializer.toJson<String>(gameId),
      'difficultyLevel': serializer.toJson<int>(difficultyLevel),
      'status': serializer.toJson<String>(status),
      'finalScore': serializer.toJson<int>(finalScore),
      'accuracy': serializer.toJson<double>(accuracy),
      'correctCount': serializer.toJson<int>(correctCount),
      'incorrectCount': serializer.toJson<int>(incorrectCount),
      'missedCount': serializer.toJson<int>(missedCount),
      'responseTimesMs': serializer.toJson<String>(responseTimesMs),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'seed': serializer.toJson<int?>(seed),
    };
  }

  GameAttemptEntry copyWith(
          {String? id,
          String? gameId,
          int? difficultyLevel,
          String? status,
          int? finalScore,
          double? accuracy,
          int? correctCount,
          int? incorrectCount,
          int? missedCount,
          String? responseTimesMs,
          DateTime? startedAt,
          DateTime? completedAt,
          Value<int?> seed = const Value.absent()}) =>
      GameAttemptEntry(
        id: id ?? this.id,
        gameId: gameId ?? this.gameId,
        difficultyLevel: difficultyLevel ?? this.difficultyLevel,
        status: status ?? this.status,
        finalScore: finalScore ?? this.finalScore,
        accuracy: accuracy ?? this.accuracy,
        correctCount: correctCount ?? this.correctCount,
        incorrectCount: incorrectCount ?? this.incorrectCount,
        missedCount: missedCount ?? this.missedCount,
        responseTimesMs: responseTimesMs ?? this.responseTimesMs,
        startedAt: startedAt ?? this.startedAt,
        completedAt: completedAt ?? this.completedAt,
        seed: seed.present ? seed.value : this.seed,
      );
  GameAttemptEntry copyWithCompanion(GameAttemptsCompanion data) {
    return GameAttemptEntry(
      id: data.id.present ? data.id.value : this.id,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      difficultyLevel: data.difficultyLevel.present
          ? data.difficultyLevel.value
          : this.difficultyLevel,
      status: data.status.present ? data.status.value : this.status,
      finalScore:
          data.finalScore.present ? data.finalScore.value : this.finalScore,
      accuracy: data.accuracy.present ? data.accuracy.value : this.accuracy,
      correctCount: data.correctCount.present
          ? data.correctCount.value
          : this.correctCount,
      incorrectCount: data.incorrectCount.present
          ? data.incorrectCount.value
          : this.incorrectCount,
      missedCount:
          data.missedCount.present ? data.missedCount.value : this.missedCount,
      responseTimesMs: data.responseTimesMs.present
          ? data.responseTimesMs.value
          : this.responseTimesMs,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      seed: data.seed.present ? data.seed.value : this.seed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GameAttemptEntry(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('difficultyLevel: $difficultyLevel, ')
          ..write('status: $status, ')
          ..write('finalScore: $finalScore, ')
          ..write('accuracy: $accuracy, ')
          ..write('correctCount: $correctCount, ')
          ..write('incorrectCount: $incorrectCount, ')
          ..write('missedCount: $missedCount, ')
          ..write('responseTimesMs: $responseTimesMs, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('seed: $seed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      gameId,
      difficultyLevel,
      status,
      finalScore,
      accuracy,
      correctCount,
      incorrectCount,
      missedCount,
      responseTimesMs,
      startedAt,
      completedAt,
      seed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GameAttemptEntry &&
          other.id == this.id &&
          other.gameId == this.gameId &&
          other.difficultyLevel == this.difficultyLevel &&
          other.status == this.status &&
          other.finalScore == this.finalScore &&
          other.accuracy == this.accuracy &&
          other.correctCount == this.correctCount &&
          other.incorrectCount == this.incorrectCount &&
          other.missedCount == this.missedCount &&
          other.responseTimesMs == this.responseTimesMs &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.seed == this.seed);
}

class GameAttemptsCompanion extends UpdateCompanion<GameAttemptEntry> {
  final Value<String> id;
  final Value<String> gameId;
  final Value<int> difficultyLevel;
  final Value<String> status;
  final Value<int> finalScore;
  final Value<double> accuracy;
  final Value<int> correctCount;
  final Value<int> incorrectCount;
  final Value<int> missedCount;
  final Value<String> responseTimesMs;
  final Value<DateTime> startedAt;
  final Value<DateTime> completedAt;
  final Value<int?> seed;
  final Value<int> rowid;
  const GameAttemptsCompanion({
    this.id = const Value.absent(),
    this.gameId = const Value.absent(),
    this.difficultyLevel = const Value.absent(),
    this.status = const Value.absent(),
    this.finalScore = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.incorrectCount = const Value.absent(),
    this.missedCount = const Value.absent(),
    this.responseTimesMs = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.seed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GameAttemptsCompanion.insert({
    required String id,
    required String gameId,
    required int difficultyLevel,
    required String status,
    required int finalScore,
    required double accuracy,
    required int correctCount,
    required int incorrectCount,
    required int missedCount,
    required String responseTimesMs,
    required DateTime startedAt,
    required DateTime completedAt,
    this.seed = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        gameId = Value(gameId),
        difficultyLevel = Value(difficultyLevel),
        status = Value(status),
        finalScore = Value(finalScore),
        accuracy = Value(accuracy),
        correctCount = Value(correctCount),
        incorrectCount = Value(incorrectCount),
        missedCount = Value(missedCount),
        responseTimesMs = Value(responseTimesMs),
        startedAt = Value(startedAt),
        completedAt = Value(completedAt);
  static Insertable<GameAttemptEntry> custom({
    Expression<String>? id,
    Expression<String>? gameId,
    Expression<int>? difficultyLevel,
    Expression<String>? status,
    Expression<int>? finalScore,
    Expression<double>? accuracy,
    Expression<int>? correctCount,
    Expression<int>? incorrectCount,
    Expression<int>? missedCount,
    Expression<String>? responseTimesMs,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<int>? seed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (gameId != null) 'game_id': gameId,
      if (difficultyLevel != null) 'difficulty_level': difficultyLevel,
      if (status != null) 'status': status,
      if (finalScore != null) 'final_score': finalScore,
      if (accuracy != null) 'accuracy': accuracy,
      if (correctCount != null) 'correct_count': correctCount,
      if (incorrectCount != null) 'incorrect_count': incorrectCount,
      if (missedCount != null) 'missed_count': missedCount,
      if (responseTimesMs != null) 'response_times_ms': responseTimesMs,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (seed != null) 'seed': seed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GameAttemptsCompanion copyWith(
      {Value<String>? id,
      Value<String>? gameId,
      Value<int>? difficultyLevel,
      Value<String>? status,
      Value<int>? finalScore,
      Value<double>? accuracy,
      Value<int>? correctCount,
      Value<int>? incorrectCount,
      Value<int>? missedCount,
      Value<String>? responseTimesMs,
      Value<DateTime>? startedAt,
      Value<DateTime>? completedAt,
      Value<int?>? seed,
      Value<int>? rowid}) {
    return GameAttemptsCompanion(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      status: status ?? this.status,
      finalScore: finalScore ?? this.finalScore,
      accuracy: accuracy ?? this.accuracy,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      missedCount: missedCount ?? this.missedCount,
      responseTimesMs: responseTimesMs ?? this.responseTimesMs,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      seed: seed ?? this.seed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<String>(gameId.value);
    }
    if (difficultyLevel.present) {
      map['difficulty_level'] = Variable<int>(difficultyLevel.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (finalScore.present) {
      map['final_score'] = Variable<int>(finalScore.value);
    }
    if (accuracy.present) {
      map['accuracy'] = Variable<double>(accuracy.value);
    }
    if (correctCount.present) {
      map['correct_count'] = Variable<int>(correctCount.value);
    }
    if (incorrectCount.present) {
      map['incorrect_count'] = Variable<int>(incorrectCount.value);
    }
    if (missedCount.present) {
      map['missed_count'] = Variable<int>(missedCount.value);
    }
    if (responseTimesMs.present) {
      map['response_times_ms'] = Variable<String>(responseTimesMs.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (seed.present) {
      map['seed'] = Variable<int>(seed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GameAttemptsCompanion(')
          ..write('id: $id, ')
          ..write('gameId: $gameId, ')
          ..write('difficultyLevel: $difficultyLevel, ')
          ..write('status: $status, ')
          ..write('finalScore: $finalScore, ')
          ..write('accuracy: $accuracy, ')
          ..write('correctCount: $correctCount, ')
          ..write('incorrectCount: $incorrectCount, ')
          ..write('missedCount: $missedCount, ')
          ..write('responseTimesMs: $responseTimesMs, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('seed: $seed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlayerGameProfilesTable extends PlayerGameProfiles
    with TableInfo<$PlayerGameProfilesTable, PlayerGameProfileEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayerGameProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<String> gameId = GeneratedColumn<String>(
      'game_id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 64),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _currentDifficultyMeta =
      const VerificationMeta('currentDifficulty');
  @override
  late final GeneratedColumn<int> currentDifficulty = GeneratedColumn<int>(
      'current_difficulty', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lastActionMeta =
      const VerificationMeta('lastAction');
  @override
  late final GeneratedColumn<String> lastAction = GeneratedColumn<String>(
      'last_action', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 32),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _lastReasonMeta =
      const VerificationMeta('lastReason');
  @override
  late final GeneratedColumn<String> lastReason = GeneratedColumn<String>(
      'last_reason', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [gameId, currentDifficulty, lastAction, lastReason, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'player_game_profiles';
  @override
  VerificationContext validateIntegrity(
      Insertable<PlayerGameProfileEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('game_id')) {
      context.handle(_gameIdMeta,
          gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta));
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('current_difficulty')) {
      context.handle(
          _currentDifficultyMeta,
          currentDifficulty.isAcceptableOrUnknown(
              data['current_difficulty']!, _currentDifficultyMeta));
    } else if (isInserting) {
      context.missing(_currentDifficultyMeta);
    }
    if (data.containsKey('last_action')) {
      context.handle(
          _lastActionMeta,
          lastAction.isAcceptableOrUnknown(
              data['last_action']!, _lastActionMeta));
    } else if (isInserting) {
      context.missing(_lastActionMeta);
    }
    if (data.containsKey('last_reason')) {
      context.handle(
          _lastReasonMeta,
          lastReason.isAcceptableOrUnknown(
              data['last_reason']!, _lastReasonMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {gameId};
  @override
  PlayerGameProfileEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayerGameProfileEntry(
      gameId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}game_id'])!,
      currentDifficulty: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}current_difficulty'])!,
      lastAction: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_action'])!,
      lastReason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_reason']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $PlayerGameProfilesTable createAlias(String alias) {
    return $PlayerGameProfilesTable(attachedDatabase, alias);
  }
}

class PlayerGameProfileEntry extends DataClass
    implements Insertable<PlayerGameProfileEntry> {
  /// Unique identifier of the game (e.g., 'memory_grid').
  final String gameId;

  /// The player's current effective difficulty level (1 through 10).
  final int currentDifficulty;

  /// The most recent adaptation action applied (e.g. 'promote', 'demote', 'maintain').
  final String lastAction;

  /// Human-readable explainable rationale for the adaptation.
  final String? lastReason;

  /// Timestamp when this difficulty level was updated (stored in UTC).
  final DateTime updatedAt;
  const PlayerGameProfileEntry(
      {required this.gameId,
      required this.currentDifficulty,
      required this.lastAction,
      this.lastReason,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['game_id'] = Variable<String>(gameId);
    map['current_difficulty'] = Variable<int>(currentDifficulty);
    map['last_action'] = Variable<String>(lastAction);
    if (!nullToAbsent || lastReason != null) {
      map['last_reason'] = Variable<String>(lastReason);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PlayerGameProfilesCompanion toCompanion(bool nullToAbsent) {
    return PlayerGameProfilesCompanion(
      gameId: Value(gameId),
      currentDifficulty: Value(currentDifficulty),
      lastAction: Value(lastAction),
      lastReason: lastReason == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReason),
      updatedAt: Value(updatedAt),
    );
  }

  factory PlayerGameProfileEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayerGameProfileEntry(
      gameId: serializer.fromJson<String>(json['gameId']),
      currentDifficulty: serializer.fromJson<int>(json['currentDifficulty']),
      lastAction: serializer.fromJson<String>(json['lastAction']),
      lastReason: serializer.fromJson<String?>(json['lastReason']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'gameId': serializer.toJson<String>(gameId),
      'currentDifficulty': serializer.toJson<int>(currentDifficulty),
      'lastAction': serializer.toJson<String>(lastAction),
      'lastReason': serializer.toJson<String?>(lastReason),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PlayerGameProfileEntry copyWith(
          {String? gameId,
          int? currentDifficulty,
          String? lastAction,
          Value<String?> lastReason = const Value.absent(),
          DateTime? updatedAt}) =>
      PlayerGameProfileEntry(
        gameId: gameId ?? this.gameId,
        currentDifficulty: currentDifficulty ?? this.currentDifficulty,
        lastAction: lastAction ?? this.lastAction,
        lastReason: lastReason.present ? lastReason.value : this.lastReason,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  PlayerGameProfileEntry copyWithCompanion(PlayerGameProfilesCompanion data) {
    return PlayerGameProfileEntry(
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      currentDifficulty: data.currentDifficulty.present
          ? data.currentDifficulty.value
          : this.currentDifficulty,
      lastAction:
          data.lastAction.present ? data.lastAction.value : this.lastAction,
      lastReason:
          data.lastReason.present ? data.lastReason.value : this.lastReason,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayerGameProfileEntry(')
          ..write('gameId: $gameId, ')
          ..write('currentDifficulty: $currentDifficulty, ')
          ..write('lastAction: $lastAction, ')
          ..write('lastReason: $lastReason, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(gameId, currentDifficulty, lastAction, lastReason, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayerGameProfileEntry &&
          other.gameId == this.gameId &&
          other.currentDifficulty == this.currentDifficulty &&
          other.lastAction == this.lastAction &&
          other.lastReason == this.lastReason &&
          other.updatedAt == this.updatedAt);
}

class PlayerGameProfilesCompanion
    extends UpdateCompanion<PlayerGameProfileEntry> {
  final Value<String> gameId;
  final Value<int> currentDifficulty;
  final Value<String> lastAction;
  final Value<String?> lastReason;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PlayerGameProfilesCompanion({
    this.gameId = const Value.absent(),
    this.currentDifficulty = const Value.absent(),
    this.lastAction = const Value.absent(),
    this.lastReason = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlayerGameProfilesCompanion.insert({
    required String gameId,
    required int currentDifficulty,
    required String lastAction,
    this.lastReason = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : gameId = Value(gameId),
        currentDifficulty = Value(currentDifficulty),
        lastAction = Value(lastAction),
        updatedAt = Value(updatedAt);
  static Insertable<PlayerGameProfileEntry> custom({
    Expression<String>? gameId,
    Expression<int>? currentDifficulty,
    Expression<String>? lastAction,
    Expression<String>? lastReason,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (gameId != null) 'game_id': gameId,
      if (currentDifficulty != null) 'current_difficulty': currentDifficulty,
      if (lastAction != null) 'last_action': lastAction,
      if (lastReason != null) 'last_reason': lastReason,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlayerGameProfilesCompanion copyWith(
      {Value<String>? gameId,
      Value<int>? currentDifficulty,
      Value<String>? lastAction,
      Value<String?>? lastReason,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return PlayerGameProfilesCompanion(
      gameId: gameId ?? this.gameId,
      currentDifficulty: currentDifficulty ?? this.currentDifficulty,
      lastAction: lastAction ?? this.lastAction,
      lastReason: lastReason ?? this.lastReason,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (gameId.present) {
      map['game_id'] = Variable<String>(gameId.value);
    }
    if (currentDifficulty.present) {
      map['current_difficulty'] = Variable<int>(currentDifficulty.value);
    }
    if (lastAction.present) {
      map['last_action'] = Variable<String>(lastAction.value);
    }
    if (lastReason.present) {
      map['last_reason'] = Variable<String>(lastReason.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayerGameProfilesCompanion(')
          ..write('gameId: $gameId, ')
          ..write('currentDifficulty: $currentDifficulty, ')
          ..write('lastAction: $lastAction, ')
          ..write('lastReason: $lastReason, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $GameAttemptsTable gameAttempts = $GameAttemptsTable(this);
  late final $PlayerGameProfilesTable playerGameProfiles =
      $PlayerGameProfilesTable(this);
  late final Index idxGameAttemptsGameCompleted = Index(
      'idx_game_attempts_game_completed',
      'CREATE INDEX idx_game_attempts_game_completed ON game_attempts (game_id, completed_at)');
  late final Index idxGameAttemptsGameScore = Index(
      'idx_game_attempts_game_score',
      'CREATE INDEX idx_game_attempts_game_score ON game_attempts (game_id, final_score)');
  late final Index idxGameAttemptsCompleted = Index(
      'idx_game_attempts_completed',
      'CREATE INDEX idx_game_attempts_completed ON game_attempts (completed_at)');
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        gameAttempts,
        playerGameProfiles,
        idxGameAttemptsGameCompleted,
        idxGameAttemptsGameScore,
        idxGameAttemptsCompleted
      ];
}

typedef $$GameAttemptsTableCreateCompanionBuilder = GameAttemptsCompanion
    Function({
  required String id,
  required String gameId,
  required int difficultyLevel,
  required String status,
  required int finalScore,
  required double accuracy,
  required int correctCount,
  required int incorrectCount,
  required int missedCount,
  required String responseTimesMs,
  required DateTime startedAt,
  required DateTime completedAt,
  Value<int?> seed,
  Value<int> rowid,
});
typedef $$GameAttemptsTableUpdateCompanionBuilder = GameAttemptsCompanion
    Function({
  Value<String> id,
  Value<String> gameId,
  Value<int> difficultyLevel,
  Value<String> status,
  Value<int> finalScore,
  Value<double> accuracy,
  Value<int> correctCount,
  Value<int> incorrectCount,
  Value<int> missedCount,
  Value<String> responseTimesMs,
  Value<DateTime> startedAt,
  Value<DateTime> completedAt,
  Value<int?> seed,
  Value<int> rowid,
});

class $$GameAttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $GameAttemptsTable> {
  $$GameAttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get gameId => $composableBuilder(
      column: $table.gameId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get difficultyLevel => $composableBuilder(
      column: $table.difficultyLevel,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get finalScore => $composableBuilder(
      column: $table.finalScore, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get accuracy => $composableBuilder(
      column: $table.accuracy, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get correctCount => $composableBuilder(
      column: $table.correctCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get incorrectCount => $composableBuilder(
      column: $table.incorrectCount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get missedCount => $composableBuilder(
      column: $table.missedCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get responseTimesMs => $composableBuilder(
      column: $table.responseTimesMs,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get seed => $composableBuilder(
      column: $table.seed, builder: (column) => ColumnFilters(column));
}

class $$GameAttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $GameAttemptsTable> {
  $$GameAttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get gameId => $composableBuilder(
      column: $table.gameId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get difficultyLevel => $composableBuilder(
      column: $table.difficultyLevel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get finalScore => $composableBuilder(
      column: $table.finalScore, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get accuracy => $composableBuilder(
      column: $table.accuracy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get correctCount => $composableBuilder(
      column: $table.correctCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get incorrectCount => $composableBuilder(
      column: $table.incorrectCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get missedCount => $composableBuilder(
      column: $table.missedCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get responseTimesMs => $composableBuilder(
      column: $table.responseTimesMs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get seed => $composableBuilder(
      column: $table.seed, builder: (column) => ColumnOrderings(column));
}

class $$GameAttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GameAttemptsTable> {
  $$GameAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get gameId =>
      $composableBuilder(column: $table.gameId, builder: (column) => column);

  GeneratedColumn<int> get difficultyLevel => $composableBuilder(
      column: $table.difficultyLevel, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get finalScore => $composableBuilder(
      column: $table.finalScore, builder: (column) => column);

  GeneratedColumn<double> get accuracy =>
      $composableBuilder(column: $table.accuracy, builder: (column) => column);

  GeneratedColumn<int> get correctCount => $composableBuilder(
      column: $table.correctCount, builder: (column) => column);

  GeneratedColumn<int> get incorrectCount => $composableBuilder(
      column: $table.incorrectCount, builder: (column) => column);

  GeneratedColumn<int> get missedCount => $composableBuilder(
      column: $table.missedCount, builder: (column) => column);

  GeneratedColumn<String> get responseTimesMs => $composableBuilder(
      column: $table.responseTimesMs, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<int> get seed =>
      $composableBuilder(column: $table.seed, builder: (column) => column);
}

class $$GameAttemptsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GameAttemptsTable,
    GameAttemptEntry,
    $$GameAttemptsTableFilterComposer,
    $$GameAttemptsTableOrderingComposer,
    $$GameAttemptsTableAnnotationComposer,
    $$GameAttemptsTableCreateCompanionBuilder,
    $$GameAttemptsTableUpdateCompanionBuilder,
    (
      GameAttemptEntry,
      BaseReferences<_$AppDatabase, $GameAttemptsTable, GameAttemptEntry>
    ),
    GameAttemptEntry,
    PrefetchHooks Function()> {
  $$GameAttemptsTableTableManager(_$AppDatabase db, $GameAttemptsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GameAttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GameAttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GameAttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> gameId = const Value.absent(),
            Value<int> difficultyLevel = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> finalScore = const Value.absent(),
            Value<double> accuracy = const Value.absent(),
            Value<int> correctCount = const Value.absent(),
            Value<int> incorrectCount = const Value.absent(),
            Value<int> missedCount = const Value.absent(),
            Value<String> responseTimesMs = const Value.absent(),
            Value<DateTime> startedAt = const Value.absent(),
            Value<DateTime> completedAt = const Value.absent(),
            Value<int?> seed = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GameAttemptsCompanion(
            id: id,
            gameId: gameId,
            difficultyLevel: difficultyLevel,
            status: status,
            finalScore: finalScore,
            accuracy: accuracy,
            correctCount: correctCount,
            incorrectCount: incorrectCount,
            missedCount: missedCount,
            responseTimesMs: responseTimesMs,
            startedAt: startedAt,
            completedAt: completedAt,
            seed: seed,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String gameId,
            required int difficultyLevel,
            required String status,
            required int finalScore,
            required double accuracy,
            required int correctCount,
            required int incorrectCount,
            required int missedCount,
            required String responseTimesMs,
            required DateTime startedAt,
            required DateTime completedAt,
            Value<int?> seed = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GameAttemptsCompanion.insert(
            id: id,
            gameId: gameId,
            difficultyLevel: difficultyLevel,
            status: status,
            finalScore: finalScore,
            accuracy: accuracy,
            correctCount: correctCount,
            incorrectCount: incorrectCount,
            missedCount: missedCount,
            responseTimesMs: responseTimesMs,
            startedAt: startedAt,
            completedAt: completedAt,
            seed: seed,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$GameAttemptsTable, GameAttemptEntry>(table),
                    BaseReferences<_$AppDatabase, $GameAttemptsTable,
                        GameAttemptEntry>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GameAttemptsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GameAttemptsTable,
    GameAttemptEntry,
    $$GameAttemptsTableFilterComposer,
    $$GameAttemptsTableOrderingComposer,
    $$GameAttemptsTableAnnotationComposer,
    $$GameAttemptsTableCreateCompanionBuilder,
    $$GameAttemptsTableUpdateCompanionBuilder,
    (
      GameAttemptEntry,
      BaseReferences<_$AppDatabase, $GameAttemptsTable, GameAttemptEntry>
    ),
    GameAttemptEntry,
    PrefetchHooks Function()>;
typedef $$PlayerGameProfilesTableCreateCompanionBuilder
    = PlayerGameProfilesCompanion Function({
  required String gameId,
  required int currentDifficulty,
  required String lastAction,
  Value<String?> lastReason,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$PlayerGameProfilesTableUpdateCompanionBuilder
    = PlayerGameProfilesCompanion Function({
  Value<String> gameId,
  Value<int> currentDifficulty,
  Value<String> lastAction,
  Value<String?> lastReason,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$PlayerGameProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $PlayerGameProfilesTable> {
  $$PlayerGameProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get gameId => $composableBuilder(
      column: $table.gameId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentDifficulty => $composableBuilder(
      column: $table.currentDifficulty,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastAction => $composableBuilder(
      column: $table.lastAction, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastReason => $composableBuilder(
      column: $table.lastReason, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$PlayerGameProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayerGameProfilesTable> {
  $$PlayerGameProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get gameId => $composableBuilder(
      column: $table.gameId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentDifficulty => $composableBuilder(
      column: $table.currentDifficulty,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastAction => $composableBuilder(
      column: $table.lastAction, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastReason => $composableBuilder(
      column: $table.lastReason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$PlayerGameProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayerGameProfilesTable> {
  $$PlayerGameProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get gameId =>
      $composableBuilder(column: $table.gameId, builder: (column) => column);

  GeneratedColumn<int> get currentDifficulty => $composableBuilder(
      column: $table.currentDifficulty, builder: (column) => column);

  GeneratedColumn<String> get lastAction => $composableBuilder(
      column: $table.lastAction, builder: (column) => column);

  GeneratedColumn<String> get lastReason => $composableBuilder(
      column: $table.lastReason, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PlayerGameProfilesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlayerGameProfilesTable,
    PlayerGameProfileEntry,
    $$PlayerGameProfilesTableFilterComposer,
    $$PlayerGameProfilesTableOrderingComposer,
    $$PlayerGameProfilesTableAnnotationComposer,
    $$PlayerGameProfilesTableCreateCompanionBuilder,
    $$PlayerGameProfilesTableUpdateCompanionBuilder,
    (
      PlayerGameProfileEntry,
      BaseReferences<_$AppDatabase, $PlayerGameProfilesTable,
          PlayerGameProfileEntry>
    ),
    PlayerGameProfileEntry,
    PrefetchHooks Function()> {
  $$PlayerGameProfilesTableTableManager(
      _$AppDatabase db, $PlayerGameProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayerGameProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayerGameProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayerGameProfilesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> gameId = const Value.absent(),
            Value<int> currentDifficulty = const Value.absent(),
            Value<String> lastAction = const Value.absent(),
            Value<String?> lastReason = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlayerGameProfilesCompanion(
            gameId: gameId,
            currentDifficulty: currentDifficulty,
            lastAction: lastAction,
            lastReason: lastReason,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String gameId,
            required int currentDifficulty,
            required String lastAction,
            Value<String?> lastReason = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PlayerGameProfilesCompanion.insert(
            gameId: gameId,
            currentDifficulty: currentDifficulty,
            lastAction: lastAction,
            lastReason: lastReason,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$PlayerGameProfilesTable,
                        PlayerGameProfileEntry>(table),
                    BaseReferences<_$AppDatabase, $PlayerGameProfilesTable,
                        PlayerGameProfileEntry>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlayerGameProfilesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PlayerGameProfilesTable,
    PlayerGameProfileEntry,
    $$PlayerGameProfilesTableFilterComposer,
    $$PlayerGameProfilesTableOrderingComposer,
    $$PlayerGameProfilesTableAnnotationComposer,
    $$PlayerGameProfilesTableCreateCompanionBuilder,
    $$PlayerGameProfilesTableUpdateCompanionBuilder,
    (
      PlayerGameProfileEntry,
      BaseReferences<_$AppDatabase, $PlayerGameProfilesTable,
          PlayerGameProfileEntry>
    ),
    PlayerGameProfileEntry,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$GameAttemptsTableTableManager get gameAttempts =>
      $$GameAttemptsTableTableManager(_db, _db.gameAttempts);
  $$PlayerGameProfilesTableTableManager get playerGameProfiles =>
      $$PlayerGameProfilesTableTableManager(_db, _db.playerGameProfiles);
}
