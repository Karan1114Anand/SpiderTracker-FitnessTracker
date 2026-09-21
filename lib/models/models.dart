/// Data models for Spider-Tracker.
///
/// These mirror the PRD section 09 data model. Every table keys on a
/// YYYY-MM-DD date string rather than a DateTime, because the app is
/// entirely local and dates are compared, grouped and displayed far more
/// often than they are arithmetic'd. `dateKey()` is the single place that
/// conversion happens.
library;

/// The canonical date key used as a primary key across every table.
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

DateTime parseDateKey(String key) => DateTime.parse(key);

// ---------------------------------------------------------------------------
// Workout
// ---------------------------------------------------------------------------

/// One prescribed exercise within a day's routine. Immutable: this comes
/// from the hard-coded plan, never from user input.
class Exercise {
  final String name;
  final int sets;

  /// Reps per set, or null when the exercise is timed.
  final int? reps;

  /// Hold/work duration in seconds, or null when the exercise is counted.
  final int? seconds;

  /// True when reps/seconds apply to each side separately (e.g. lunges).
  final bool perSide;

  const Exercise({
    required this.name,
    required this.sets,
    this.reps,
    this.seconds,
    this.perSide = false,
  }) : assert(
         reps != null || seconds != null,
         'An exercise needs either reps or seconds',
       );

  /// Renders as "4×15", "3×45s", "3×12 each".
  String get prescription {
    final unit = reps != null ? '$reps' : '${seconds}s';
    final side = perSide ? ' each' : '';
    return '$sets×$unit$side';
  }
}

/// A day's prescribed routine from the hard-coded plan.
class WorkoutDay {
  /// Full name, e.g. "Push — Chest & Shoulders".
  final String title;

  /// Short form for tight UI spaces, e.g. "Push".
  final String short;
  final List<Exercise> exercises;
  final String duration;

  const WorkoutDay({
    required this.title,
    required this.short,
    required this.exercises,
    required this.duration,
  });

  /// A day with no exercises is a rest day; it still counts toward a streak.
  bool get isRest => exercises.isEmpty;
  bool get isTraining => exercises.isNotEmpty;
}

/// Per-exercise progress within a logged workout.
class SetProgress {
  final String exercise;
  int setsCompleted;

  SetProgress({required this.exercise, this.setsCompleted = 0});

  Map<String, dynamic> toJson() => {
    'exercise': exercise,
    'sets_completed': setsCompleted,
  };

  factory SetProgress.fromJson(Map<String, dynamic> j) => SetProgress(
    exercise: j['exercise'] as String,
    setsCompleted: j['sets_completed'] as int? ?? 0,
  );
}

/// A logged workout. Table: workout_log, primary key `date`.
class WorkoutLog {
  final String date;
  final String dayType;
  final List<SetProgress> setsDone;
  final bool completed;
  final String? notes;

  const WorkoutLog({
    required this.date,
    required this.dayType,
    required this.setsDone,
    required this.completed,
    this.notes,
  });
}

// ---------------------------------------------------------------------------
// Meals
// ---------------------------------------------------------------------------

enum MealType { breakfast, lunch, snack, dinner }

extension MealTypeLabel on MealType {
  String get label => switch (this) {
    MealType.breakfast => 'Breakfast',
    MealType.lunch => 'Lunch',
    MealType.snack => 'Snack',
    MealType.dinner => 'Dinner',
  };

  String get window => switch (this) {
    MealType.breakfast => '7–8 AM',
    MealType.lunch => '1–2 PM',
    MealType.snack => '4–5 PM',
    MealType.dinner => '7–8 PM',
  };
}

/// User's own verdict on a meal. Drives the daily diet score.
enum MealQuality { good, okay, cheat }

extension MealQualityScore on MealQuality {
  /// PRD section 05: good = 2, okay = 1, cheat = 0. Max 8 across 4 meals.
  int get points => switch (this) {
    MealQuality.good => 2,
    MealQuality.okay => 1,
    MealQuality.cheat => 0,
  };

  String get label => switch (this) {
    MealQuality.good => 'Good',
    MealQuality.okay => 'Okay',
    MealQuality.cheat => 'Cheat',
  };
}

/// A selectable mess-food item. `flagged` drives the gentle warning —
/// it never blocks logging, by design.
class MealOption {
  final String name;
  final bool flagged;

  const MealOption(this.name, {this.flagged = false});
}

/// A logged meal. Table: meal_log, keyed on (date, mealType).
class MealLog {
  final String date;
  final MealType mealType;
  final List<String> items;
  final MealQuality quality;

  const MealLog({
    required this.date,
    required this.mealType,
    required this.items,
    required this.quality,
  });
}

// ---------------------------------------------------------------------------
// Weight, runs, app state
// ---------------------------------------------------------------------------

/// Table: weight_log. Monday dates only — enforced at the service layer.
class WeightLog {
  final String date;
  final double weightKg;
  final String? note;

  const WeightLog({required this.date, required this.weightKg, this.note});
}

/// Table: run_log. Only meaningful once running unlocks on 1 Oct 2026.
class RunLog {
  final String date;
  final double distanceKm;
  final int durationMin;

  const RunLog({
    required this.date,
    required this.distanceKm,
    required this.durationMin,
  });

  /// Minutes per kilometre, the pace runners actually think in.
  double get paceMinPerKm => distanceKm > 0 ? durationMin / distanceKm : 0;

  String get paceLabel {
    if (distanceKm <= 0) return '—';
    final p = paceMinPerKm;
    final m = p.floor();
    final s = ((p - m) * 60).round();
    return "$m'${s.toString().padLeft(2, '0')}\"/km";
  }
}

/// Single-record app state. Table: app_state.
class AppState {
  final double startWeight;
  final double goalWeight;
  final String goalDate;
  final int currentStreak;
  final bool runUnlocked;

  const AppState({
    required this.startWeight,
    required this.goalWeight,
    required this.goalDate,
    required this.currentStreak,
    required this.runUnlocked,
  });

  /// Placeholder until sign-up: nothing user-facing shows these values, and
  /// sign-up overwrites them with the user's own numbers.
  static const AppState initial = AppState(
    startWeight: 0,
    goalWeight: 0,
    goalDate: '1970-01-01',
    currentStreak: 0,
    runUnlocked: false,
  );

  int daysToGoal(DateTime now) => parseDateKey(
    goalDate,
  ).difference(DateTime(now.year, now.month, now.day)).inDays;
}

/// Water and sleep for one day. Sleep is the night that ended this morning.
class WellnessLog {
  const WellnessLog({required this.date, this.waterMl = 0, this.sleepHours});

  static const int waterGoalMl = 3000;
  static const int glassMl = 250;
  static const double sleepGoalHours = 8;

  final String date;
  final int waterMl;
  final double? sleepHours;
}

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "2026-09-22" as "22 Sep 2026".
String prettyDateKey(String key) {
  final d = parseDateKey(key);
  return '${d.day} ${_monthNames[d.month - 1]} ${d.year}';
}
