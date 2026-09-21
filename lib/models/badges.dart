/// Badges: milestones derived from the logs.
///
/// Like points, badges are never stored. Each one is a pure check over the
/// data, so it stays correct if a log is edited, and each reports its
/// progress so a locked badge can show how close it is.
library;

import 'models.dart';

class BadgeStatus {
  const BadgeStatus({
    required this.id,
    required this.name,
    required this.description,
    required this.value,
    required this.target,
    this.unit = '',
  });

  final String id;
  final String name;
  final String description;

  /// Progress so far, in [unit]s. Capped at [target] for display.
  final double value;
  final double target;
  final String unit;

  bool get earned => value >= target;

  /// "3 / 7" or "0.4 / 1 kg".
  String get progressLabel {
    String f(double v) =>
        v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
    final shown = value > target ? target : value;
    return '${f(shown)} / ${f(target)}${unit.isEmpty ? '' : ' $unit'}';
  }
}

/// Everything the badge checks look at.
class BadgeInput {
  const BadgeInput({
    required this.workouts,
    required this.dietScores,
    required this.wellness,
    required this.runs,
    required this.startKg,
    required this.goalKg,
    required this.latestKg,
    required this.bestDayXp,
    required this.level,
  });

  final List<WorkoutLog> workouts;
  final Map<String, int> dietScores;
  final Map<String, WellnessLog> wellness;
  final List<RunLog> runs;
  final double startKg;
  final double goalKg;
  final double? latestKg;

  /// Most points earned on any single day.
  final int bestDayXp;
  final int level;
}

/// Longest run of consecutive days with a completed workout.
int longestWorkoutStreak(List<WorkoutLog> workouts) {
  final days = <DateTime>{
    for (final w in workouts)
      if (w.completed) parseDateKey(w.date),
  }.toList()..sort();
  var best = 0, run = 0;
  DateTime? prev;
  for (final d in days) {
    run = (prev != null && d.difference(prev).inDays == 1) ? run + 1 : 1;
    if (run > best) best = run;
    prev = d;
  }
  return best;
}

List<BadgeStatus> computeBadges(BadgeInput i) {
  final completed = i.workouts.where((w) => w.completed).length;
  final streak = longestWorkoutStreak(i.workouts);
  final waterDays = i.wellness.values
      .where((w) => w.waterMl >= WellnessLog.waterGoalMl)
      .length;
  final sleepDays = i.wellness.values
      .where((w) => (w.sleepHours ?? 0) >= 7)
      .length;
  final cleanDays = i.dietScores.values.where((s) => s >= 8).length;
  final goodDietDays = i.dietScores.values.where((s) => s >= 6).length;
  final runKm = i.runs.fold<double>(0, (s, r) => s + r.distanceKm);

  final toLose = i.startKg - i.goalKg;
  final lost = i.latestKg == null ? 0.0 : i.startKg - i.latestKg!;
  final lostClamped = lost < 0 ? 0.0 : lost;

  BadgeStatus b(
    String id,
    String name,
    String desc,
    num value,
    num target, [
    String unit = '',
  ]) => BadgeStatus(
    id: id,
    name: name,
    description: desc,
    value: value.toDouble(),
    target: target.toDouble(),
    unit: unit,
  );

  return [
    b('first_workout', 'First Strand', 'Complete a workout.', completed, 1),
    b(
      'streak_3',
      'Three in a Row',
      'Complete workouts 3 days running.',
      streak,
      3,
      'days',
    ),
    b(
      'streak_7',
      'Full Week',
      'Complete workouts 7 days running.',
      streak,
      7,
      'days',
    ),
    b(
      'streak_14',
      'Fortnight',
      'Complete workouts 14 days running.',
      streak,
      14,
      'days',
    ),
    b(
      'streak_30',
      'Unbroken',
      'Complete workouts 30 days running.',
      streak,
      30,
      'days',
    ),
    b(
      'water_day',
      'Hydrated',
      'Reach your 3 L water goal in a day.',
      waterDays,
      1,
    ),
    b(
      'water_week',
      'Well Watered',
      'Reach the water goal on 7 days.',
      waterDays,
      7,
      'days',
    ),
    b('sleep_night', 'Rested', 'Sleep 7 hours or more.', sleepDays, 1),
    b(
      'sleep_week',
      'Sleep Routine',
      'Sleep 7+ hours on 7 nights.',
      sleepDays,
      7,
      'nights',
    ),
    b(
      'diet_day',
      'Clean Plate',
      'Score 8 out of 8 on food in a day.',
      cleanDays,
      1,
    ),
    b(
      'diet_week',
      'Fuelled Right',
      'Score 6+ on food on 7 days.',
      goodDietDays,
      7,
      'days',
    ),
    b('run_first', 'First Mile', 'Log a run.', i.runs.length, 1),
    b('run_5', 'Regular', 'Log 5 runs.', i.runs.length, 5, 'runs'),
    b('run_50km', 'Long Haul', 'Run 50 km in total.', runKm, 50, 'km'),
    b(
      'perfect_day',
      'Perfect Day',
      'Earn 100 points in a single day.',
      i.bestDayXp,
      100,
      'pts',
    ),
    b('level_5', 'Rising', 'Reach level 5.', i.level, 5),
    b('level_10', 'Veteran', 'Reach level 10.', i.level, 10),
    if (toLose > 0) ...[
      b(
        'weight_1',
        'First Kilo',
        'Lose your first kilogram.',
        lostClamped,
        1,
        'kg',
      ),
      b(
        'weight_half',
        'Halfway',
        'Get halfway to your goal weight.',
        lostClamped,
        toLose / 2,
        'kg',
      ),
      b(
        'weight_goal',
        'Goal Reached',
        'Reach your goal weight.',
        lostClamped,
        toLose,
        'kg',
      ),
    ],
  ];
}
