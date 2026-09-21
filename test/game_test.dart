import 'package:flutter_test/flutter_test.dart';
import 'package:spider_tracker/models/game.dart';
import 'package:spider_tracker/models/models.dart';

WorkoutLog _workout({required bool done, int sets = 0}) => WorkoutLog(
  date: '2026-09-22',
  dayType: 'Push',
  setsDone: [SetProgress(exercise: 'A', setsCompleted: sets)],
  completed: done,
);

void main() {
  group('daily points', () {
    test('an empty day earns nothing', () {
      expect(dayXp().total, 0);
    });

    test('a perfect day hits the maximum', () {
      final xp = dayXp(
        workout: _workout(done: true, sets: 10),
        dietScore: 8,
        wellness: const WellnessLog(date: 'd', waterMl: 3000, sleepHours: 8),
        run: const RunLog(date: 'd', distanceKm: 3, durationMin: 20),
      );
      expect(xp.total, DayXp.maxTotal);
    });

    test('food is four points per diet point', () {
      expect(dayXp(dietScore: 5).food, 20);
    });

    test('partial workout earns partial credit, capped below a full one', () {
      expect(dayXp(workout: _workout(done: false, sets: 3)).workout, 6);
      expect(
        dayXp(workout: _workout(done: false, sets: 50)).workout,
        lessThan(DayXp.maxWorkout),
      );
    });

    test('water and sleep scale and cap', () {
      const half = WellnessLog(date: 'd', waterMl: 1500, sleepHours: 3.5);
      final xp = dayXp(wellness: half);
      expect(xp.water, 8);
      expect(xp.sleep, 8);
      const lots = WellnessLog(date: 'd', waterMl: 9000, sleepHours: 12);
      expect(dayXp(wellness: lots).water, DayXp.maxWater);
      expect(dayXp(wellness: lots).sleep, DayXp.maxSleep);
    });
  });

  group('levels', () {
    test('level 1 starts at zero points', () {
      final l = levelForXp(0);
      expect(l.number, 1);
      expect(l.title, 'Bitten');
      expect(l.xpToNext, 100);
    });

    test('thresholds are hit exactly', () {
      expect(levelForXp(99).number, 1);
      expect(levelForXp(100).number, 2);
      expect(levelForXp(299).number, 2);
      expect(levelForXp(300).number, 3);
    });

    test('progress runs from 0 to 1 within a level', () {
      expect(levelForXp(100).progress, 0);
      expect(levelForXp(200).progress, 0.5);
    });

    test('titles run out gracefully at high levels', () {
      expect(levelTitle(99), levelTitles.last);
    });

    test('a strong day is a real step, not a rounding error', () {
      expect(levelForXp(dayXp(dietScore: 8).total * 4).number, greaterThan(1));
    });
  });
}
