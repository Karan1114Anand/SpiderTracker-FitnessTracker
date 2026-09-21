/// Spider-Tracker — local-only fitness and diet tracker.
///
/// Entry point and the shell that hosts the five tabs. State lives in
/// [AppRepository] rather than a state-management package: the whole app is
/// one user on one device with a handful of tables, so a ChangeNotifier
/// over the database is the honest amount of machinery.
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart' show databaseFactory;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/meal_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/run_screen.dart';
import 'screens/workout_screen.dart';
import 'services/repository.dart';
import 'services/sfx.dart';
import 'theme/app_theme.dart';
import 'widgets/web_shot.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // The app ships to Android, where sqflite uses the platform SQLite. In a
  // browser there is no such thing, so the web preview swaps in the
  // IndexedDB-backed factory. Preview-only: this path never runs on device.
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: SpiderColors.bg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const SpiderTrackerApp());
}

class SpiderTrackerApp extends StatefulWidget {
  const SpiderTrackerApp({super.key});

  @override
  State<SpiderTrackerApp> createState() => _SpiderTrackerAppState();
}

class _SpiderTrackerAppState extends State<SpiderTrackerApp> {
  final AppRepository _repo = AppRepository();

  @override
  void initState() {
    super.initState();
    _repo.load();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spider-Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      // Above the Navigator so pushed routes (profile, re-plan) see it too.
      builder: (context, child) =>
          RepositoryScope(repository: _repo, child: child!),
      home: const RootShell(),
    );
  }
}

/// Inherited access to the single repository instance.
class RepositoryScope extends InheritedNotifier<AppRepository> {
  const RepositoryScope({
    super.key,
    required AppRepository repository,
    required super.child,
  }) : super(notifier: repository);

  static AppRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RepositoryScope>();
    assert(scope != null, 'No RepositoryScope above this widget');
    return scope!.notifier!;
  }
}

/// Lets dashboard cards switch tabs without a Navigator push, so the nav
/// bar stays the single source of truth for where you are.
class TabSwitcher extends InheritedWidget {
  const TabSwitcher({super.key, required this.goToTab, required super.child});

  final void Function(int index) goToTab;

  static void Function(int) of(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<TabSwitcher>();
    assert(w != null, 'No TabSwitcher above this widget');
    return w!.goToTab;
  }

  @override
  bool updateShouldNotify(TabSwitcher oldWidget) => false;
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);

    if (repo.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!repo.onboarded) return const OnboardingScreen();

    final visible = _index;

    // One notice per achievement, shown after the frame that produced it
    // so it never interrupts a build.
    final up = repo.takeLevelUp();
    final fresh = repo.takeNewBadges();
    if (up != null || fresh.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Sfx.levelUp();
        WebFx.shoot(context);
        showDialog<void>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(
              fresh.length + (up == null ? 0 : 1) > 1
                  ? 'Achievements unlocked'
                  : 'Achievement unlocked',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (up != null) Text('Level ${up.number}: ${up.title}'),
                for (final b in fresh) Text('Badge: ${b.name}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Nice'),
              ),
            ],
          ),
        );
      });
    }

    const pages = [
      HomeScreen(),
      WorkoutScreen(),
      MealScreen(),
      RunScreen(),
      ProgressScreen(),
    ];

    const dests = <NavigationDestination>[
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Home',
      ),
      NavigationDestination(
        icon: Icon(Icons.fitness_center_outlined),
        selectedIcon: Icon(Icons.fitness_center),
        label: 'Workout',
      ),
      NavigationDestination(
        icon: Icon(Icons.restaurant_menu_outlined),
        selectedIcon: Icon(Icons.restaurant_menu),
        label: 'Meals',
      ),
      NavigationDestination(
        icon: Icon(Icons.directions_run_outlined),
        selectedIcon: Icon(Icons.directions_run),
        label: 'Run',
      ),
      NavigationDestination(
        icon: Icon(Icons.show_chart),
        selectedIcon: Icon(Icons.insights),
        label: 'Progress',
      ),
    ];

    return Scaffold(
      body: TabSwitcher(
        goToTab: (i) => setState(() => _index = i),
        child: SafeArea(
          bottom: false,
          // Keyed on the plan so a re-plan rebuilds every screen fresh.
          child: KeyedSubtree(
            key: ObjectKey(repo.plan),
            child: IndexedStack(index: _index, children: pages),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: visible,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: dests,
      ),
    );
  }
}
