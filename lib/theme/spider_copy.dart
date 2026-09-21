/// Every user-facing string, in one place so the tone can be read and
/// changed together. Plain, short, no exclamation marks, no scolding.
library;

abstract final class SpiderCopy {
  static const String workoutComplete = 'Workout complete. Nice work.';
  static const String cheatFoodSelected =
      'Flagged against your goal. It is still logged, no judgement.';
  static const String streakSevenDay = '7-day streak. Keep it going.';
  static const String missedDay = 'Missed a day. Pick it back up tomorrow.';
  static const String goalWeightReached = 'Goal weight reached.';
  static const String mondayWeighIn = "It's Monday. Time to weigh in.";

  static const String waterTitle = 'Water';
  static const String sleepTitle = 'Sleep';
  static const String noSleepYet = 'Not logged';

  static const String onboardTitle = 'Set up your plan';
  static const String onboardSubtitle =
      'Enter your details. An AI assistant can build your plan, or you can build your own workouts.';
  static const String editTitle = 'New plan';
  static const String editFinish = 'Replace my plan';
  static const String onboardGenerate = 'Generate prompt';
  static const String onboardRegenerate = 'Update prompt';
  static const String onboardCopyHelp =
      'Paste it into ChatGPT, Claude, Gemini or any assistant, then bring its reply back below.';
  static const String onboardFinish = 'Start tracking';
  static const String onboardPrivacy =
      'Everything stays on this phone. The app never goes online; only what you paste into an assistant leaves.';

  static const String streakTitle = 'Streak';
  static const String webStrengthTitle = 'Diet today';
  static const String todayTitle = 'Today';
  static const String daysToGoalLabel = 'Days left';
  static const String streakLabel = 'Streak';
  static const String workoutsLabel = 'Workouts';
  static const String weightLabel = 'Weight';
  static const String toGoalLabel = 'To goal';

  static const String noStreakYet = 'No streak yet';
  static const String noMealsYet = 'No meals logged today.';
  static const String noWeightYet = 'No weigh-in yet';
  static const String runsLocked = 'Running is not unlocked yet.';

  static const String logMeal = 'Log meal';
  static const String finishWorkout = 'Finish workout';
  static const String logWeight = 'Log weigh-in';

  static String streakLine(int days) {
    if (days <= 0) return noStreakYet;
    if (days == 1) return '1 day';
    if (days == 7) return '7 days';
    return '$days days';
  }

  /// Verdict on a daily diet score of 0-8.
  static String webStrengthLabel(int score) => switch (score) {
    <= 1 => 'Off track',
    2 || 3 => 'Needs work',
    4 || 5 => 'Fair',
    6 || 7 => 'Good',
    _ => 'Excellent',
  };

  /// Weigh-in result line. [delta] is kg change since the previous entry.
  static String weighInResult(double delta) {
    if (delta <= -0.1) return '${delta.abs().toStringAsFixed(1)} kg down.';
    if (delta >= 0.1) return '${delta.toStringAsFixed(1)} kg up.';
    return 'No change.';
  }

  static String daysToGoal(int days) {
    if (days > 1) return '$days days left.';
    if (days == 1) return '1 day left.';
    if (days == 0) return 'Goal day.';
    return 'Past the goal date.';
  }
}
