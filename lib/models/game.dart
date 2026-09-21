/// Points and levels.
///
/// There is no calorie counting, so progress is measured in points earned
/// for the habits that actually move the needle: what you eat, how much you
/// drink, how you sleep, whether you train and whether you run.
///
/// Points are never stored. They are a pure function of the logs, so
/// editing or deleting a log corrects the total by itself and the numbers
/// can never drift out of sync with the data.
library;

import 'models.dart';

/// One day's points, split by habit.
class DayXp {
  const DayXp({
    this.workout = 0,
    this.food = 0,
    this.water = 0,
    this.sleep = 0,
    this.run = 0,
  });

  final int workout;
  final int food;
  final int water;
  final int sleep;
  final int run;

  int get total => workout + food + water + sleep + run;

  static const int maxWorkout = 30;
  static const int maxFood = 32; // 8 diet points x 4
  static const int maxWater = 15;
  static const int maxSleep = 15;
  static const int maxRun = 20;
  static const int maxTotal =
      maxWorkout + maxFood + maxWater + maxSleep + maxRun;
}

/// Points for one day from that day's logs (any of which may be absent).
DayXp dayXp({
  WorkoutLog? workout,
  int dietScore = 0,
  WellnessLog? wellness,
  RunLog? run,
}) {
  var w = 0;
  if (workout != null) {
    final sets = workout.setsDone.fold<int>(0, (s, p) => s + p.setsCompleted);
    w = workout.completed
        ? DayXp.maxWorkout
        : (sets * 2).clamp(0, DayXp.maxWorkout - 10);
  }

  final food = (dietScore * 4).clamp(0, DayXp.maxFood);

  final water = wellness == null
      ? 0
      : (DayXp.maxWater * wellness.waterMl / WellnessLog.waterGoalMl)
            .round()
            .clamp(0, DayXp.maxWater);

  final hours = wellness?.sleepHours;
  final sleep = hours == null
      ? 0
      : (DayXp.maxSleep * hours / 7).round().clamp(0, DayXp.maxSleep);

  return DayXp(
    workout: w,
    food: food,
    water: water,
    sleep: sleep,
    run: run == null ? 0 : DayXp.maxRun,
  );
}

/// A player's standing for a total point count.
class Level {
  const Level({
    required this.number,
    required this.title,
    required this.xpIntoLevel,
    required this.xpForLevel,
  });

  final int number;
  final String title;

  /// Points earned since this level began.
  final int xpIntoLevel;

  /// Points needed to get from this level to the next.
  final int xpForLevel;

  double get progress =>
      xpForLevel == 0 ? 0 : (xpIntoLevel / xpForLevel).clamp(0.0, 1.0);

  int get xpToNext => xpForLevel - xpIntoLevel;
}

/// Total points at which [level] begins. Level 1 starts at 0.
int xpAtLevel(int level) => 50 * level * (level - 1);

const List<String> levelTitles = [
  'Bitten',
  'Wall-Crawler',
  'Web-Slinger',
  'Street Level',
  'Friendly Neighbour',
  'Spider-Sense',
  'Amazing',
  'Spectacular',
  'Superior',
  'Ultimate',
  'Spider-Verse',
  'Legend',
];

String levelTitle(int level) =>
    levelTitles[(level - 1).clamp(0, levelTitles.length - 1)];

Level levelForXp(int xp) {
  final total = xp < 0 ? 0 : xp;
  var n = 1;
  while (xpAtLevel(n + 1) <= total) {
    n++;
  }
  return Level(
    number: n,
    title: levelTitle(n),
    xpIntoLevel: total - xpAtLevel(n),
    xpForLevel: xpAtLevel(n + 1) - xpAtLevel(n),
  );
}
