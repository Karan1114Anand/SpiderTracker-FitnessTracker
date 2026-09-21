import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spider_tracker/models/models.dart';
import 'package:spider_tracker/models/user_plan.dart';
import 'package:spider_tracker/screens/plan_editor_screen.dart';

void main() {
  test('an empty week is seven rest days, Monday first', () {
    final w = emptyWeek();
    expect(w.length, 7);
    expect(w.every((d) => d.isRest), isTrue);
    expect(w.first.title, 'Monday');
    expect(w.last.title, 'Sunday');
  });

  test('swapping the week keeps meals and running', () {
    final plan = UserPlan(
      week: emptyWeek(),
      meals: {
        for (final t in MealType.values) t: const [MealOption('Oats')],
      },
    );
    final next = plan.withWeek([
      const WorkoutDay(
        title: 'A',
        short: 'A',
        duration: '30 min',
        exercises: [Exercise(name: 'X', sets: 3, reps: 10)],
      ),
      ...emptyWeek().skip(1),
    ]);
    expect(next.week.first.isTraining, isTrue);
    expect(next.options(MealType.lunch).single.name, 'Oats');
  });

  testWidgets('saving a week with no exercises is refused', (tester) async {
    var saved = false;
    await tester.pumpWidget(MaterialApp(
      home: PlanEditorScreen(
        initial: emptyWeek(),
        onSave: (_) async => saved = true,
      ),
    ));
    await tester.tap(find.text('Save plan'));
    await tester.pump();
    expect(saved, isFalse);
    expect(find.text('Add exercises to at least one day.'), findsOneWidget);
  });

  testWidgets('a day can be built and saved', (tester) async {
    List<WorkoutDay>? result;
    await tester.pumpWidget(MaterialApp(
      home: PlanEditorScreen(
        initial: emptyWeek(),
        onSave: (w) async => result = w,
      ),
    ));
    await tester.tap(find.text('Monday'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add exercise'));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextField, 'Exercise'), 'Push-ups');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save plan'));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(result!.first.exercises.single.name, 'Push-ups');
    expect(result!.first.exercises.single.sets, 3);
    expect(result![1].isRest, isTrue);
  });
}
