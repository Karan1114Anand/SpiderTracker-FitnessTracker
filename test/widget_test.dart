import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spider_tracker/main.dart';
import 'package:spider_tracker/screens/home_screen.dart';
import 'package:spider_tracker/screens/meal_screen.dart';
import 'package:spider_tracker/screens/progress_screen.dart';
import 'package:spider_tracker/screens/run_screen.dart';
import 'package:spider_tracker/screens/weight_screen.dart';
import 'package:spider_tracker/screens/workout_screen.dart';
import 'package:spider_tracker/services/repository.dart';

/// Pumps [screen] under a repository that has not loaded, which every
/// screen must render as a spinner rather than throw.
Widget _host(Widget screen, AppRepository repo) => MaterialApp(
  home: RepositoryScope(
    repository: repo,
    child: TabSwitcher(
      goToTab: (_) {},
      child: Scaffold(body: screen),
    ),
  ),
);

void main() {
  final screens = <String, Widget>{
    'home': const HomeScreen(),
    'workout': const WorkoutScreen(),
    'meal': const MealScreen(),
    'run': const RunScreen(),
    'weight': const WeightScreen(),
    'progress': const ProgressScreen(),
  };

  for (final e in screens.entries) {
    testWidgets('${e.key} screen shows a spinner while loading', (
      tester,
    ) async {
      await tester.pumpWidget(_host(e.value, AppRepository()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  }
}
