/// Tests for the logic that is easy to get subtly wrong and hard to spot
/// by using the app: streak boundaries, diet scoring, pace, and the run
/// unlock date.
///
/// These run against pure functions and model code, so they need no
/// device and no sqflite binding.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:spider_tracker/models/models.dart';

void main() {
  group('dateKey', () {
    test('pads month and day', () {
      expect(dateKey(DateTime(2026, 1, 5)), '2026-01-05');
    });

    test('round-trips through parseDateKey', () {
      final d = DateTime(2026, 10, 1);
      expect(parseDateKey(dateKey(d)), d);
    });
  });

  group('diet score', () {
    test('good is 2, okay is 1, cheat is 0', () {
      expect(MealQuality.good.points, 2);
      expect(MealQuality.okay.points, 1);
      expect(MealQuality.cheat.points, 0);
    });

    test('four good meals reach the PRD maximum of 8', () {
      final total = MealType.values
          .map((_) => MealQuality.good.points)
          .fold<int>(0, (a, b) => a + b);
      expect(total, 8);
    });
  });

  group('exercise prescription', () {
    test('formats reps', () {
      const e = Exercise(name: 'Push-ups', sets: 4, reps: 15);
      expect(e.prescription, '4×15');
    });

    test('formats timed holds', () {
      const e = Exercise(name: 'Plank', sets: 3, seconds: 45);
      expect(e.prescription, '3×45s');
    });

    test('marks per-side work', () {
      const e = Exercise(
        name: 'Reverse lunges',
        sets: 3,
        reps: 12,
        perSide: true,
      );
      expect(e.prescription, '3×12 each');
    });
  });

  group('run pace', () {
    test('formats minutes per kilometre', () {
      const r = RunLog(date: '2026-10-01', distanceKm: 5, durationMin: 30);
      expect(r.paceLabel, "6'00\"/km");
    });

    test('handles a fractional pace', () {
      const r = RunLog(date: '2026-10-01', distanceKm: 4, durationMin: 26);
      expect(r.paceLabel, "6'30\"/km");
    });

    test('zero distance does not divide by zero', () {
      const r = RunLog(date: '2026-10-01', distanceKm: 0, durationMin: 10);
      expect(r.paceMinPerKm, 0);
      expect(r.paceLabel, '—');
    });
  });

  group('app state', () {
    test('starts empty and locked', () {
      const s = AppState.initial;
      expect(s.runUnlocked, isFalse);
      expect(s.currentStreak, 0);
    });

    test('days to goal counts down to the goal date', () {
      const s = AppState(
        startWeight: 70,
        goalWeight: 62,
        goalDate: '2026-12-01',
        currentStreak: 0,
        runUnlocked: false,
      );
      expect(s.daysToGoal(DateTime(2026, 11, 30)), 1);
      expect(s.daysToGoal(DateTime(2026, 12, 1)), 0);
    });
  });
}
