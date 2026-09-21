/// The single source of truth the screens read from.
///
/// Wraps [SpiderDatabase] in a ChangeNotifier and keeps today's slice of
/// data in memory. Screens never touch the database directly: they read
/// fields here and call mutators, so there is exactly one place where a
/// write triggers a rebuild.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/mess_menu.dart';
import '../models/badges.dart';
import '../models/game.dart';
import '../models/models.dart';
import '../models/user_plan.dart';
import 'database.dart';
import 'sfx.dart';

class AppRepository extends ChangeNotifier {
  final SpiderDatabase _db = SpiderDatabase.instance;

  AppState _state = AppState.initial;
  AppState get state => _state;

  bool _loading = true;
  bool get loading => _loading;

  /// Today's date key, captured once per load so a rebuild at midnight
  /// cannot show one screen yesterday and another today.
  String _today = dateKey(DateTime.now());
  String get today => _today;

  WorkoutLog? _todayWorkout;
  WorkoutLog? get todayWorkout => _todayWorkout;

  List<MealLog> _todayMeals = const [];
  List<MealLog> get todayMeals => _todayMeals;

  RunLog? _todayRun;
  RunLog? get todayRun => _todayRun;

  List<WeightLog> _weights = const [];
  List<WeightLog> get weights => _weights;

  List<WorkoutLog> _allWorkouts = const [];
  List<WorkoutLog> get allWorkouts => _allWorkouts;

  bool _soundOn = true;

  /// Whether sound effects play. Persisted, and mirrored to [Sfx].
  bool get soundOn => _soundOn;

  Future<void> setSoundOn(bool on) async {
    _soundOn = on;
    Sfx.enabled = on;
    await _db.saveSetting('sound', on ? '1' : '0');
    notifyListeners();
  }

  List<RunLog> _runs = const [];

  /// Every logged run, oldest first.
  List<RunLog> get runs => _runs;

  Map<String, WellnessLog> _wellnessByDate = const {};

  // -------------------------------------------------------------------------
  // Points and levels — derived from the logs, never stored.
  // -------------------------------------------------------------------------

  /// Points earned on [date].
  DayXp xpOn(String date) => dayXp(
    workout: _allWorkouts.where((w) => w.date == date).firstOrNull,
    dietScore: _dietScores[date] ?? 0,
    wellness: _wellnessByDate[date],
    run: _runs.where((r) => r.date == date).firstOrNull,
  );

  DayXp get todayXp => xpOn(_today);

  /// Lifetime points across every day that has any log.
  int get totalXp {
    final days = <String>{
      for (final w in _allWorkouts) w.date,
      ..._dietScores.keys,
      ..._wellnessByDate.keys,
      for (final r in _runs) r.date,
    };
    return days.fold(0, (sum, d) => sum + xpOn(d).total);
  }

  Level get level => levelForXp(totalXp);

  /// Most points earned on any single day.
  int get bestDayXp {
    var best = 0;
    for (final d in {
      for (final w in _allWorkouts) w.date,
      ..._dietScores.keys,
      ..._wellnessByDate.keys,
      for (final r in _runs) r.date,
    }) {
      final t = xpOn(d).total;
      if (t > best) best = t;
    }
    return best;
  }

  /// Every badge with its progress, earned or not.
  List<BadgeStatus> get badges => computeBadges(
    BadgeInput(
      workouts: _allWorkouts,
      dietScores: _dietScores,
      wellness: _wellnessByDate,
      runs: _runs,
      startKg: _state.startWeight,
      goalKg: _state.goalWeight,
      latestKg: latestWeightKg,
      bestDayXp: bestDayXp,
      level: level.number,
    ),
  );

  Set<String>? _earnedBadges;
  List<BadgeStatus> _newBadges = const [];

  /// Badges earned since the last call; empty afterwards.
  List<BadgeStatus> takeNewBadges() {
    final n = _newBadges;
    _newBadges = const [];
    return n;
  }

  int? _lastLevel;
  Level? _levelUp;

  /// The level just reached, once; null afterwards. Read by the shell to
  /// show a single congratulation per level.
  Level? takeLevelUp() {
    final l = _levelUp;
    _levelUp = null;
    return l;
  }

  @override
  void notifyListeners() {
    final now = level;
    if (_lastLevel != null && now.number > _lastLevel!) _levelUp = now;
    _lastLevel = now.number;

    final earned = {
      for (final b in badges)
        if (b.earned) b.id,
    };
    if (_earnedBadges != null) {
      final fresh = badges
          .where((b) => b.earned && !_earnedBadges!.contains(b.id))
          .toList();
      if (fresh.isNotEmpty) _newBadges = [..._newBadges, ...fresh];
    }
    _earnedBadges = earned;
    super.notifyListeners();
  }

  WellnessLog _todayWellness = WellnessLog(date: dateKey(DateTime.now()));
  WellnessLog get todayWellness => _todayWellness;

  Map<String, int> _dietScores = const {};

  /// Diet score per logged day, for the progress history.
  Map<String, int> get dietScores => _dietScores;

  /// The prescribed routine for today, from the hard-coded plan.
  WorkoutDay get todayPlan => _plan.workoutFor(DateTime.now());

  UserPlan _plan = UserPlan.empty();
  UserPlan get plan => _plan;

  UserProfile? _profile;
  UserProfile? get profile => _profile;

  /// False until the user has finished sign-up (or chosen the built-in plan).
  bool _onboarded = false;
  bool get onboarded => _onboarded;

  /// Diet score out of 8 for today (PRD section 05).
  int get todayDietScore =>
      _todayMeals.fold(0, (sum, m) => sum + m.quality.points);

  double? get latestWeightKg =>
      _weights.isEmpty ? null : _weights.last.weightKg;

  /// Kilograms still to lose. Negative once the goal is passed.
  double? get remainingKg {
    final w = latestWeightKg;
    return w == null ? null : w - _state.goalWeight;
  }

  int get daysToGoal => _state.daysToGoal(DateTime.now());

  /// True when today is Monday and no weight has been logged for it.
  /// Weigh-in is Monday-only by design (PRD section 03).
  bool get weighInDue {
    final now = DateTime.now();
    if (now.weekday != DateTime.monday) return false;
    return !_weights.any((w) => w.date == _today);
  }

  Future<void> load() async {
    _today = dateKey(DateTime.now());
    final stored = await _db.loadPlanJson();
    if (stored == null) {
      _plan = UserPlan.empty();
      _profile = null;
      _onboarded = false;
    } else {
      try {
        _plan = UserPlan.fromJson(
          jsonDecode(stored.plan) as Map<String, dynamic>,
        );
        final pj = jsonDecode(stored.profile) as Map<String, dynamic>;
        _profile = pj.isEmpty ? null : UserProfile.fromJson(pj);
        _onboarded = true;
      } catch (_) {
        _onboarded = false; // corrupt plan: send them back through sign-up
      }
    }
    _state = await _db.refreshDerivedState(
      DateTime.now(),
      runUnlocked: _plan.isRunUnlocked(DateTime.now()),
    );
    _todayWorkout = await _db.workoutOn(_today);
    _todayMeals = await _db.mealsOn(_today);
    _todayRun = await _db.runOn(_today);
    _runs = await _db.allRuns();
    _wellnessByDate = await _db.allWellness();
    _soundOn = (await _db.setting('sound')) != '0';
    Sfx.enabled = _soundOn;
    _weights = await _db.allWeights();
    _allWorkouts = await _db.allWorkouts();
    _dietScores = await _db.allDietScores();
    _todayWellness = await _db.wellnessOn(_today);
    await _loadCustomItems();
    _loading = false;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Mutations. Each writes, then reloads the affected slice and notifies.
  // -------------------------------------------------------------------------

  /// Records per-exercise progress. [completed] is computed by the caller
  /// because only the workout screen knows the full prescription.
  Future<void> saveWorkout({
    required List<SetProgress> progress,
    required bool completed,
    String? notes,
  }) async {
    await _db.saveWorkout(
      WorkoutLog(
        date: _today,
        dayType: todayPlan.title,
        setsDone: progress,
        completed: completed,
        notes: notes,
      ),
    );
    _todayWorkout = await _db.workoutOn(_today);
    _allWorkouts = await _db.allWorkouts();
    _state = await _db.refreshDerivedState(
      DateTime.now(),
      runUnlocked: _plan.isRunUnlocked(DateTime.now()),
    );
    notifyListeners();
  }

  /// Adds [glasses] (may be negative) of water, never below zero.
  Future<void> addWater(int glasses) async {
    final ml = (_todayWellness.waterMl + glasses * WellnessLog.glassMl).clamp(
      0,
      10000,
    );
    _todayWellness = WellnessLog(
      date: _today,
      waterMl: ml,
      sleepHours: _todayWellness.sleepHours,
    );
    await _db.saveWellness(_todayWellness);
    _wellnessByDate = {..._wellnessByDate, _today: _todayWellness};
    notifyListeners();
  }

  /// Sets last night's sleep; null clears it.
  Future<void> setSleep(double? hours) async {
    _todayWellness = WellnessLog(
      date: _today,
      waterMl: _todayWellness.waterMl,
      sleepHours: (hours == null || hours <= 0)
          ? null
          : hours.clamp(0, 16).toDouble(),
    );
    await _db.saveWellness(_todayWellness);
    _wellnessByDate = {..._wellnessByDate, _today: _todayWellness};
    notifyListeners();
  }

  /// Finishes sign-up: stores the profile and plan, and points the goal,
  /// countdown and weight history at this user.
  Future<void> completeOnboarding(UserProfile profile, UserPlan plan) async {
    final now = DateTime.now();
    await _db.savePlanJson(
      jsonEncode(profile.toJson()),
      jsonEncode(plan.toJson()),
    );
    await _db.saveAppState(
      AppState(
        startWeight: profile.currentKg,
        goalWeight: profile.goalKg,
        goalDate: dateKey(profile.goalDateFrom(now)),
        currentStreak: 0,
        runUnlocked: false,
      ),
    );
    await _db.saveWeight(
      WeightLog(date: dateKey(now), weightKg: profile.currentKg),
    );
    await load();
  }

  /// Swaps in a new profile and plan but keeps every log and the original
  /// start weight, so re-planning never costs the user their history.
  Future<void> replan(UserProfile profile, UserPlan plan) async {
    final now = DateTime.now();
    await _db.savePlanJson(
      jsonEncode(profile.toJson()),
      jsonEncode(plan.toJson()),
    );
    await _db.saveAppState(
      AppState(
        startWeight: _state.startWeight,
        goalWeight: profile.goalKg,
        goalDate: dateKey(profile.goalDateFrom(now)),
        currentStreak: _state.currentStreak,
        runUnlocked: _state.runUnlocked,
      ),
    );
    await load();
  }

  /// Replaces just the workout week, keeping the profile, meals and every log.
  Future<void> updateWorkoutPlan(List<WorkoutDay> week) async {
    _plan = _plan.withWeek(week);
    await _db.savePlanJson(
      jsonEncode(_profile?.toJson() ?? <String, dynamic>{}),
      jsonEncode(_plan.toJson()),
    );
    await load();
  }

  /// Deletes everything and returns to the sign-up screen.
  Future<void> resetEverything() async {
    await _db.resetAll();
    _plan = UserPlan.empty();
    _profile = null;
    _onboarded = false;
    await load();
  }

  Future<void> saveMeal({
    required MealType type,
    required List<String> items,
    required MealQuality quality,
  }) async {
    await _db.saveMeal(
      MealLog(date: _today, mealType: type, items: items, quality: quality),
    );
    _todayMeals = await _db.mealsOn(_today);
    _dietScores = await _db.allDietScores();
    notifyListeners();
  }

  Future<void> saveWeight(double kg, {String? note}) async {
    await _db.saveWeight(WeightLog(date: _today, weightKg: kg, note: note));
    _weights = await _db.allWeights();
    notifyListeners();
  }

  Future<void> saveRun({
    required double distanceKm,
    required int durationMin,
  }) async {
    await _db.saveRun(
      RunLog(date: _today, distanceKm: distanceKm, durationMin: durationMin),
    );
    _todayRun = await _db.runOn(_today);
    _runs = await _db.allRuns();
    notifyListeners();
  }

  /// Custom items the user has typed before, per meal type, most-used
  /// first. Loaded with the rest of today's slice so the picker never
  /// waits on a query.
  Map<MealType, List<MealOption>> _customItems = const {};

  /// Presets plus remembered custom items, ready for the picker.
  List<MealOption> optionsForMeal(MealType type) => [
    ..._plan.options(type),
    ...(_customItems[type] ?? const <MealOption>[]),
  ];

  List<MealOption> customOnly(MealType type) =>
      _customItems[type] ?? const <MealOption>[];

  /// Adds a hand-typed item and returns it. Flagging is automatic — see
  /// [shouldFlagCustom] — so a typed "samosa" still triggers the warning.
  Future<MealOption> addCustomItem(MealType type, String name) async {
    final trimmed = name.trim();
    final flagged = shouldFlagCustom(trimmed);
    if (!_plan.isPreset(type, trimmed)) {
      await _db.rememberCustomItem(type, trimmed, flagged: flagged);
      await _loadCustomItems();
      notifyListeners();
    }
    return MealOption(trimmed, flagged: flagged);
  }

  Future<void> removeCustomItem(MealType type, String name) async {
    await _db.forgetCustomItem(type, name);
    await _loadCustomItems();
    notifyListeners();
  }

  Future<void> _loadCustomItems() async {
    final map = <MealType, List<MealOption>>{};
    for (final t in MealType.values) {
      map[t] = await _db.customItems(t);
    }
    _customItems = map;
  }

  MealLog? mealFor(MealType type) {
    for (final m in _todayMeals) {
      if (m.mealType == type) return m;
    }
    return null;
  }
}
