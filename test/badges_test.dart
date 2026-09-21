import 'package:flutter_test/flutter_test.dart';
import 'package:spider_tracker/models/badges.dart';
import 'package:spider_tracker/models/models.dart';

WorkoutLog _w(String date, {bool done = true}) =>
    WorkoutLog(date: date, dayType: 'x', setsDone: const [], completed: done);

BadgeInput _input({
  List<WorkoutLog> workouts = const [],
  Map<String, int> diet = const {},
  Map<String, WellnessLog> wellness = const {},
  List<RunLog> runs = const [],
  double? latest,
  int bestDay = 0,
  int level = 1,
}) => BadgeInput(
  workouts: workouts,
  dietScores: diet,
  wellness: wellness,
  runs: runs,
  startKg: 95,
  goalKg: 85,
  latestKg: latest,
  bestDayXp: bestDay,
  level: level,
);

BadgeStatus _get(List<BadgeStatus> l, String id) =>
    l.firstWhere((b) => b.id == id);

void main() {
  test('nothing is earned on a blank slate', () {
    expect(computeBadges(_input()).where((b) => b.earned), isEmpty);
  });

  test('longest streak counts only consecutive completed days', () {
    final logs = [
      _w('2026-09-01'),
      _w('2026-09-02'),
      _w('2026-09-03'),
      _w('2026-09-05'),
      _w('2026-09-06', done: false),
    ];
    expect(longestWorkoutStreak(logs), 3);
    final badges = computeBadges(_input(workouts: logs));
    expect(_get(badges, 'streak_3').earned, isTrue);
    expect(_get(badges, 'streak_7').earned, isFalse);
    expect(_get(badges, 'first_workout').earned, isTrue);
  });

  test('locked badges report progress', () {
    final b = _get(
      computeBadges(_input(workouts: [_w('2026-09-01'), _w('2026-09-02')])),
      'streak_7',
    );
    expect(b.progressLabel, '2 / 7 days');
  });

  test('habit badges read the right logs', () {
    final badges = computeBadges(
      _input(
        diet: {'a': 8, 'b': 6},
        wellness: {
          'a': const WellnessLog(date: 'a', waterMl: 3000, sleepHours: 7.5),
        },
        runs: const [RunLog(date: 'a', distanceKm: 60, durationMin: 400)],
      ),
    );
    expect(_get(badges, 'diet_day').earned, isTrue);
    expect(_get(badges, 'water_day').earned, isTrue);
    expect(_get(badges, 'sleep_night').earned, isTrue);
    expect(_get(badges, 'run_first').earned, isTrue);
    expect(_get(badges, 'run_50km').earned, isTrue);
    expect(_get(badges, 'water_week').earned, isFalse);
  });

  test('weight badges scale to the user goal and never go negative', () {
    var b = computeBadges(_input(latest: 90));
    expect(_get(b, 'weight_half').earned, isTrue);
    expect(_get(b, 'weight_goal').earned, isFalse);
    b = computeBadges(_input(latest: 100));
    expect(_get(b, 'weight_1').value, 0);
  });
}
