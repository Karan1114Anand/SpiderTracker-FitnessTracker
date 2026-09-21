/// Local persistence for Spider-Tracker.
///
/// Everything lives in one SQLite file on the phone. No backend, no sync,
/// no login — per PRD section 07. The only data that ever leaves the
/// device is a CSV the user exports deliberately (V2).
///
/// Dates are TEXT in YYYY-MM-DD form rather than INTEGER epochs: every
/// query here is "what happened on this day" or "these days in order",
/// and lexical ordering on that format is chronological ordering.
library;

import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';

class SpiderDatabase {
  static const _fileName = 'spider_tracker.db';

  /// 2 added custom_item, 3 added wellness_log, 4 added plan_store, 5 added settings. Bump this and add an onUpgrade branch whenever
  /// the schema changes, or existing installs crash on a missing table.
  static const _version = 5;

  static SpiderDatabase? _instance;
  static SpiderDatabase get instance => _instance ??= SpiderDatabase._();
  SpiderDatabase._();

  Database? _db;

  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), _fileName);
    return openDatabase(
      path,
      version: _version,
      onCreate: _create,
      onUpgrade: _upgrade,
    );
  }

  Future<void> _upgrade(Database d, int from, int to) async {
    if (from < 2) {
      await d.execute('''
        CREATE TABLE IF NOT EXISTS custom_item (
          meal_type TEXT NOT NULL,
          name      TEXT NOT NULL,
          flagged   INTEGER NOT NULL,
          uses      INTEGER NOT NULL DEFAULT 1,
          PRIMARY KEY (meal_type, name)
        )
      ''');
    }
    if (from < 3) {
      await d.execute('''
        CREATE TABLE IF NOT EXISTS wellness_log (
          date        TEXT PRIMARY KEY,
          water_ml    INTEGER NOT NULL DEFAULT 0,
          sleep_hours REAL
        )
      ''');
    }
    if (from < 4) {
      await d.execute('''
        CREATE TABLE IF NOT EXISTS plan_store (
          id           INTEGER PRIMARY KEY CHECK (id = 1),
          profile_json TEXT NOT NULL,
          plan_json    TEXT NOT NULL
        )
      ''');
    }
    if (from < 5) {
      await d.execute('''
        CREATE TABLE IF NOT EXISTS settings (
          key   TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
    }
  }

  Future<void> _create(Database d, int version) async {
    await d.execute('''
      CREATE TABLE workout_log (
        date      TEXT PRIMARY KEY,
        day_type  TEXT NOT NULL,
        sets_done TEXT NOT NULL,
        completed INTEGER NOT NULL,
        notes     TEXT
      )
    ''');

    // Composite key: one row per meal slot per day, so re-logging lunch
    // overwrites rather than duplicating.
    await d.execute('''
      CREATE TABLE meal_log (
        date      TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        items     TEXT NOT NULL,
        quality   TEXT NOT NULL,
        PRIMARY KEY (date, meal_type)
      )
    ''');

    await d.execute('''
      CREATE TABLE weight_log (
        date      TEXT PRIMARY KEY,
        weight_kg REAL NOT NULL,
        note      TEXT
      )
    ''');

    await d.execute('''
      CREATE TABLE run_log (
        date         TEXT PRIMARY KEY,
        distance_km  REAL NOT NULL,
        duration_min INTEGER NOT NULL
      )
    ''');

    // Items the user typed that aren't in the preset menu. Kept per meal
    // type so "Omelette" offered at breakfast doesn't clutter dinner.
    // `uses` lets the picker show the most-eaten ones first: one mess
    // serves the same handful of dishes on rotation, so the list converges
    // on that mess within a fortnight.
    await d.execute('''
      CREATE TABLE custom_item (
        meal_type TEXT NOT NULL,
        name      TEXT NOT NULL,
        flagged   INTEGER NOT NULL,
        uses      INTEGER NOT NULL DEFAULT 1,
        PRIMARY KEY (meal_type, name)
      )
    ''');

    await d.execute('''
      CREATE TABLE IF NOT EXISTS wellness_log (
        date        TEXT PRIMARY KEY,
        water_ml    INTEGER NOT NULL DEFAULT 0,
        sleep_hours REAL
      )
    ''');

    await d.execute('''
      CREATE TABLE settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // The user's profile and generated plan, as JSON. Absent until sign-up.
    await d.execute('''
      CREATE TABLE IF NOT EXISTS plan_store (
        id           INTEGER PRIMARY KEY CHECK (id = 1),
        profile_json TEXT NOT NULL,
        plan_json    TEXT NOT NULL
      )
    ''');

    // Single-row table. The id CHECK keeps it that way.
    await d.execute('''
      CREATE TABLE app_state (
        id             INTEGER PRIMARY KEY CHECK (id = 1),
        start_weight   REAL NOT NULL,
        goal_weight    REAL NOT NULL,
        goal_date      TEXT NOT NULL,
        current_streak INTEGER NOT NULL,
        run_unlocked   INTEGER NOT NULL
      )
    ''');

    const s = AppState.initial;
    await d.insert('app_state', {
      'id': 1,
      'start_weight': s.startWeight,
      'goal_weight': s.goalWeight,
      'goal_date': s.goalDate,
      'current_streak': s.currentStreak,
      'run_unlocked': s.runUnlocked ? 1 : 0,
    });
  }

  // -------------------------------------------------------------------------
  // Workouts
  // -------------------------------------------------------------------------

  Future<void> saveWorkout(WorkoutLog log) async {
    final d = await db;
    await d.insert('workout_log', {
      'date': log.date,
      'day_type': log.dayType,
      'sets_done': jsonEncode(log.setsDone.map((e) => e.toJson()).toList()),
      'completed': log.completed ? 1 : 0,
      'notes': log.notes,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<WorkoutLog?> workoutOn(String date) async {
    final d = await db;
    final rows = await d.query(
      'workout_log',
      where: 'date = ?',
      whereArgs: [date],
    );
    return rows.isEmpty ? null : _workoutFrom(rows.first);
  }

  Future<List<WorkoutLog>> allWorkouts() async {
    final d = await db;
    final rows = await d.query('workout_log', orderBy: 'date ASC');
    return rows.map(_workoutFrom).toList();
  }

  WorkoutLog _workoutFrom(Map<String, Object?> r) => WorkoutLog(
    date: r['date'] as String,
    dayType: r['day_type'] as String,
    setsDone: (jsonDecode(r['sets_done'] as String) as List)
        .map((e) => SetProgress.fromJson(e as Map<String, dynamic>))
        .toList(),
    completed: (r['completed'] as int) == 1,
    notes: r['notes'] as String?,
  );

  // -------------------------------------------------------------------------
  // Meals
  // -------------------------------------------------------------------------

  Future<void> saveMeal(MealLog log) async {
    final d = await db;
    await d.insert('meal_log', {
      'date': log.date,
      'meal_type': log.mealType.name,
      'items': jsonEncode(log.items),
      'quality': log.quality.name,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<MealLog>> mealsOn(String date) async {
    final d = await db;
    final rows = await d.query(
      'meal_log',
      where: 'date = ?',
      whereArgs: [date],
    );
    return rows.map(_mealFrom).toList();
  }

  MealLog _mealFrom(Map<String, Object?> r) => MealLog(
    date: r['date'] as String,
    mealType: MealType.values.byName(r['meal_type'] as String),
    items: (jsonDecode(r['items'] as String) as List).cast<String>(),
    quality: MealQuality.values.byName(r['quality'] as String),
  );

  /// Custom items for [type], most-used first so the mess's actual
  /// rotation floats to the top of the picker.
  Future<List<MealOption>> customItems(MealType type) async {
    final d = await db;
    final rows = await d.query(
      'custom_item',
      where: 'meal_type = ?',
      whereArgs: [type.name],
      orderBy: 'uses DESC, name ASC',
    );
    return rows
        .map(
          (r) => MealOption(
            r['name'] as String,
            flagged: (r['flagged'] as int) == 1,
          ),
        )
        .toList();
  }

  /// Records a hand-typed item, or bumps its use count if already known.
  Future<void> rememberCustomItem(
    MealType type,
    String name, {
    required bool flagged,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final d = await db;
    final existing = await d.query(
      'custom_item',
      where: 'meal_type = ? AND name = ?',
      whereArgs: [type.name, trimmed],
    );

    if (existing.isEmpty) {
      await d.insert('custom_item', {
        'meal_type': type.name,
        'name': trimmed,
        'flagged': flagged ? 1 : 0,
        'uses': 1,
      });
    } else {
      await d.rawUpdate(
        'UPDATE custom_item SET uses = uses + 1 '
        'WHERE meal_type = ? AND name = ?',
        [type.name, trimmed],
      );
    }
  }

  Future<void> forgetCustomItem(MealType type, String name) async {
    final d = await db;
    await d.delete(
      'custom_item',
      where: 'meal_type = ? AND name = ?',
      whereArgs: [type.name, name],
    );
  }

  /// Daily diet score out of 8 (PRD section 05). Unlogged meals score
  /// nothing — an empty day reads 0, not "perfect".
  Future<int> dietScoreOn(String date) async {
    final meals = await mealsOn(date);
    return meals.fold<int>(0, (sum, m) => sum + m.quality.points);
  }

  /// Diet scores for every day that has at least one meal logged.
  Future<Map<String, int>> allDietScores() async {
    final d = await db;
    final rows = await d.query('meal_log', columns: ['date', 'quality']);
    final scores = <String, int>{};
    for (final r in rows) {
      final q = MealQuality.values.firstWhere(
        (e) => e.name == r['quality'],
        orElse: () => MealQuality.cheat,
      );
      final date = r['date'] as String;
      scores[date] = (scores[date] ?? 0) + q.points;
    }
    return scores;
  }

  Future<String?> setting(String key) async {
    final d = await db;
    final rows = await d.query('settings', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> saveSetting(String key, String value) async {
    final d = await db;
    await d.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Wipes every log, the plan and the profile, back to a fresh install.
  Future<void> resetAll() async {
    final d = await db;
    await d.transaction((t) async {
      for (final table in [
        'workout_log',
        'meal_log',
        'weight_log',
        'run_log',
        'custom_item',
        'wellness_log',
        'plan_store',
        'settings',
      ]) {
        await t.delete(table);
      }
    });
    await saveAppState(AppState.initial);
  }

  // -------------------------------------------------------------------------
  // Profile and plan
  // -------------------------------------------------------------------------

  /// Stored (profile, plan) JSON, or null before sign-up.
  Future<({String profile, String plan})?> loadPlanJson() async {
    final d = await db;
    final rows = await d.query('plan_store', where: 'id = 1');
    if (rows.isEmpty) return null;
    return (
      profile: rows.first['profile_json'] as String,
      plan: rows.first['plan_json'] as String,
    );
  }

  Future<void> savePlanJson(String profile, String plan) async {
    final d = await db;
    await d.insert('plan_store', {
      'id': 1,
      'profile_json': profile,
      'plan_json': plan,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // -------------------------------------------------------------------------
  // Water and sleep
  // -------------------------------------------------------------------------

  Future<WellnessLog> wellnessOn(String date) async {
    final d = await db;
    final rows = await d.query(
      'wellness_log',
      where: 'date = ?',
      whereArgs: [date],
    );
    if (rows.isEmpty) return WellnessLog(date: date);
    final r = rows.first;
    return WellnessLog(
      date: date,
      waterMl: r['water_ml'] as int,
      sleepHours: (r['sleep_hours'] as num?)?.toDouble(),
    );
  }

  Future<Map<String, WellnessLog>> allWellness() async {
    final d = await db;
    final rows = await d.query('wellness_log');
    return {
      for (final r in rows)
        r['date'] as String: WellnessLog(
          date: r['date'] as String,
          waterMl: r['water_ml'] as int,
          sleepHours: (r['sleep_hours'] as num?)?.toDouble(),
        ),
    };
  }

  Future<void> saveWellness(WellnessLog log) async {
    final d = await db;
    await d.insert('wellness_log', {
      'date': log.date,
      'water_ml': log.waterMl,
      'sleep_hours': log.sleepHours,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // -------------------------------------------------------------------------
  // Weight
  // -------------------------------------------------------------------------

  Future<void> saveWeight(WeightLog log) async {
    final d = await db;
    await d.insert('weight_log', {
      'date': log.date,
      'weight_kg': log.weightKg,
      'note': log.note,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<WeightLog>> allWeights() async {
    final d = await db;
    final rows = await d.query('weight_log', orderBy: 'date ASC');
    return rows
        .map(
          (r) => WeightLog(
            date: r['date'] as String,
            weightKg: r['weight_kg'] as double,
            note: r['note'] as String?,
          ),
        )
        .toList();
  }

  Future<WeightLog?> latestWeight() async {
    final d = await db;
    final rows = await d.query('weight_log', orderBy: 'date DESC', limit: 1);
    if (rows.isEmpty) return null;
    final r = rows.first;
    return WeightLog(
      date: r['date'] as String,
      weightKg: r['weight_kg'] as double,
      note: r['note'] as String?,
    );
  }

  // -------------------------------------------------------------------------
  // Runs
  // -------------------------------------------------------------------------

  Future<void> saveRun(RunLog log) async {
    final d = await db;
    await d.insert('run_log', {
      'date': log.date,
      'distance_km': log.distanceKm,
      'duration_min': log.durationMin,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<RunLog>> allRuns() async {
    final d = await db;
    final rows = await d.query('run_log', orderBy: 'date ASC');
    return rows.map(_runFrom).toList();
  }

  Future<RunLog?> runOn(String date) async {
    final d = await db;
    final rows = await d.query('run_log', where: 'date = ?', whereArgs: [date]);
    return rows.isEmpty ? null : _runFrom(rows.first);
  }

  RunLog _runFrom(Map<String, Object?> r) => RunLog(
    date: r['date'] as String,
    distanceKm: r['distance_km'] as double,
    durationMin: r['duration_min'] as int,
  );

  // -------------------------------------------------------------------------
  // App state and streak
  // -------------------------------------------------------------------------

  Future<AppState> appState() async {
    final d = await db;
    final rows = await d.query('app_state', where: 'id = 1');
    if (rows.isEmpty) return AppState.initial;
    final r = rows.first;
    return AppState(
      startWeight: r['start_weight'] as double,
      goalWeight: r['goal_weight'] as double,
      goalDate: r['goal_date'] as String,
      currentStreak: r['current_streak'] as int,
      runUnlocked: (r['run_unlocked'] as int) == 1,
    );
  }

  Future<void> saveAppState(AppState s) async {
    final d = await db;
    await d.update('app_state', {
      'start_weight': s.startWeight,
      'goal_weight': s.goalWeight,
      'goal_date': s.goalDate,
      'current_streak': s.currentStreak,
      'run_unlocked': s.runUnlocked ? 1 : 0,
    }, where: 'id = 1');
  }

  /// Consecutive days ending today (or yesterday) with a completed workout.
  ///
  /// Counting back from yesterday when today is not yet logged is
  /// deliberate: at 9am the streak shouldn't read zero just because the
  /// morning session hasn't happened. It breaks only once a full day has
  /// passed unlogged. Rest days count — the plan prescribes them, so
  /// honouring the plan is the behaviour being rewarded.
  Future<int> computeStreak(DateTime now) async {
    final d = await db;
    final rows = await d.query(
      'workout_log',
      columns: ['date'],
      where: 'completed = 1',
      orderBy: 'date DESC',
    );
    if (rows.isEmpty) return 0;

    final logged = rows.map((r) => r['date'] as String).toSet();
    final today = DateTime(now.year, now.month, now.day);

    var cursor = logged.contains(dateKey(today))
        ? today
        : today.subtract(const Duration(days: 1));

    var streak = 0;
    while (logged.contains(dateKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Recomputes the streak and unlock flag, then persists them. Call on
  /// launch and after any workout is logged.
  Future<AppState> refreshDerivedState(
    DateTime now, {
    required bool runUnlocked,
  }) async {
    final current = await appState();
    final updated = AppState(
      startWeight: current.startWeight,
      goalWeight: current.goalWeight,
      goalDate: current.goalDate,
      currentStreak: await computeStreak(now),
      runUnlocked: runUnlocked,
    );
    await saveAppState(updated);
    return updated;
  }
}
