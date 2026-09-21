import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:spider_tracker/data/mess_menu.dart';
import 'package:spider_tracker/models/models.dart';
import 'package:spider_tracker/models/user_plan.dart';
import 'package:spider_tracker/services/plan_prompt.dart';

const _profile = UserProfile(
  name: 'Asha',
  age: 24,
  heightCm: 165,
  currentKg: 70,
  goalKg: 62,
  weeks: 12,
  workoutType: 'Bodyweight at home',
  daysPerWeek: 4,
  diet: 'vegetarian',
);

Map<String, dynamic> _day(String t, {bool rest = false}) => {
  'title': t,
  'short': t.substring(0, 3),
  'duration': '30 min',
  'exercises': rest
      ? []
      : [
          {'name': 'Move A', 'sets': 3, 'reps': 10},
          {'name': 'Hold B', 'sets': 2, 'seconds': 30},
          {'name': 'Side C', 'sets': 3, 'reps': 8, 'per_side': true},
        ],
};

List<Map<String, dynamic>> _items(String p) => [
  for (var i = 0; i < 4; i++) {'name': '$p $i', 'flagged': i == 3},
];

/// What an LLM reply should look like, using made-up names on purpose: the
/// app must show exactly what the plan says and nothing of its own.
Map<String, dynamic> _reply() => {
  'week': [
    _day('Alpha'),
    _day('Bravo', rest: true),
    _day('Charlie'),
    _day('Delta', rest: true),
    _day('Echo'),
    _day('Foxtrot'),
    _day('Golf', rest: true),
  ],
  'meals': {
    'breakfast': _items('B'),
    'lunch': _items('L'),
    'snack': _items('S'),
    'dinner': _items('D'),
  },
  'run': {
    'window': 'evening',
    'days': [1, 3, 5],
    'stages': [
      {
        'from': '2026-10-01',
        'min_km': 2,
        'max_km': 3,
        'pace': 'easy',
        'note': 'n',
      },
      {
        'from': '2026-11-01',
        'min_km': 4,
        'max_km': 5,
        'pace': 'brisk',
        'note': 'n',
      },
    ],
  },
};

void main() {
  test('pasted reply becomes exactly the plan it describes', () {
    final plan = parsePlanReply('Here:\n```json\n${jsonEncode(_reply())}\n```');
    expect(plan.week.map((d) => d.title), [
      'Alpha',
      'Bravo',
      'Charlie',
      'Delta',
      'Echo',
      'Foxtrot',
      'Golf',
    ]);
    expect(plan.week[1].isRest, isTrue);
    expect(plan.week[0].exercises[2].perSide, isTrue);
    expect(plan.week[0].exercises[1].prescription, '2×30s');
    expect(plan.options(MealType.lunch).map((o) => o.name), [
      'L 0',
      'L 1',
      'L 2',
      'L 3',
    ]);
    expect(plan.options(MealType.dinner).last.flagged, isTrue);
    expect(plan.isRunDay(DateTime(2026, 10, 2)), isTrue); // Friday
    expect(plan.isRunDay(DateTime(2026, 10, 3)), isFalse);
  });

  test('plan survives a JSON round trip', () {
    final a = UserPlan.fromJson(_reply());
    final b = UserPlan.fromJson(
      jsonDecode(jsonEncode(a.toJson())) as Map<String, dynamic>,
    );
    expect(b.week.map((d) => d.title), a.week.map((d) => d.title));
    expect(b.options(MealType.snack).length, 4);
    expect(b.runStages.length, 2);
  });

  test('the app ships no dishes of its own', () {
    final empty = UserPlan.empty();
    for (final t in MealType.values) {
      expect(empty.options(t), isEmpty);
    }
    expect(empty.week.every((d) => d.isRest), isTrue);
  });

  test('a custom item is flagged by keyword, not by any preset list', () {
    expect(shouldFlagCustom('Samosa'), isTrue);
    expect(shouldFlagCustom('Grilled fish'), isFalse);
  });

  test(
    'prompt carries the profile and the goal date, with no sample dishes',
    () {
      final p = buildPlanPrompt(_profile, DateTime(2026, 9, 22));
      expect(p, contains('Asha'));
      expect(p, contains('165 cm'));
      expect(p, contains('lose 8.0 kg'));
      expect(p, contains('2026-12-15'));
      for (final w in ['Oats', 'Pastry', 'Push-ups', 'Plank', 'Poha', 'Roti']) {
        expect(p, isNot(contains(w)), reason: 'prompt leaks "$w"');
      }
    },
  );

  test('bad replies give errors', () {
    expect(() => parsePlanReply('no json here'), throwsFormatException);
    expect(() => parsePlanReply('{"week": []}'), throwsFormatException);
    expect(() => parsePlanReply('{"week": [1,2'), throwsFormatException);
    final thin = _reply()
      ..['meals'] = {'breakfast': [], 'lunch': [], 'snack': [], 'dinner': []};
    expect(() => UserPlan.fromJson(thin), throwsFormatException);
  });

  test('a plan without running never unlocks the run tab', () {
    final plan = UserPlan.fromJson(_reply()..remove('run'));
    expect(plan.isRunUnlocked(DateTime(2027, 1, 1)), isFalse);
    expect(plan.runTargetFor(DateTime(2027, 1, 1)), isNull);
  });

  test('run stages apply by date and the last one holds', () {
    final plan = UserPlan.fromJson(_reply());
    expect(plan.runTargetFor(DateTime(2026, 9, 30)), isNull);
    expect(plan.runTargetFor(DateTime(2026, 10, 2))!.minKm, 2);
    expect(plan.runTargetFor(DateTime(2027, 3, 1))!.minKm, 4);
  });
}
