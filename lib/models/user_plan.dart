/// A user's personal plan: the week's workouts, their meal options and an
/// optional running ladder. Everything the app used to hard-code lives here
/// so it can come from an LLM-generated JSON document instead.
library;

import '../data/workout_plan.dart';
import 'models.dart';

/// What the user tells us at sign-up. Feeds the prompt; stored so the app
/// can greet them and the prompt can be regenerated.
class UserProfile {
  const UserProfile({
    required this.name,
    required this.age,
    required this.heightCm,
    required this.currentKg,
    required this.goalKg,
    required this.weeks,
    required this.workoutType,
    required this.daysPerWeek,
    this.diet = '',
  });

  final String name;
  final int age;
  final double heightCm;
  final double currentKg;
  final double goalKg;

  /// Weeks from today until the goal date.
  final int weeks;

  /// Free text such as "bodyweight at home" or "gym with dumbbells".
  final String workoutType;
  final int daysPerWeek;
  final String diet;

  DateTime goalDateFrom(DateTime now) =>
      DateTime(now.year, now.month, now.day).add(Duration(days: weeks * 7));

  Map<String, dynamic> toJson() => {
    'name': name,
    'age': age,
    'height_cm': heightCm,
    'current_kg': currentKg,
    'goal_kg': goalKg,
    'weeks': weeks,
    'workout_type': workoutType,
    'days_per_week': daysPerWeek,
    'diet': diet,
  };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    name: j['name'] as String,
    age: j['age'] as int,
    heightCm: (j['height_cm'] as num).toDouble(),
    currentKg: (j['current_kg'] as num).toDouble(),
    goalKg: (j['goal_kg'] as num).toDouble(),
    weeks: j['weeks'] as int,
    workoutType: j['workout_type'] as String,
    daysPerWeek: j['days_per_week'] as int,
    diet: j['diet'] as String? ?? '',
  );
}

/// A running stage that applies from [from] until the next stage starts.
class RunStage {
  const RunStage({required this.from, required this.target});
  final DateTime from;
  final RunTarget target;
}

class UserPlan {
  UserPlan({
    required this.week,
    required this.meals,
    this.runStages = const [],
    this.runDays = const {1, 2, 3, 4, 5, 6},
    this.runWindow = '',
  }) : assert(week.length == 7, 'A plan covers Monday to Sunday');

  /// Index 0 = Monday … 6 = Sunday.
  final List<WorkoutDay> week;
  final Map<MealType, List<MealOption>> meals;
  final List<RunStage> runStages;

  /// `DateTime.weekday` values on which a run is scheduled.
  final Set<int> runDays;
  final String runWindow;

  /// The state before sign-up: all rest, no food. Never shown to a user.
  factory UserPlan.empty() => UserPlan(
    week: List.filled(
      7,
      const WorkoutDay(
        title: 'Rest',
        short: 'Rest',
        duration: '—',
        exercises: [],
      ),
    ),
    meals: {for (final t in MealType.values) t: const <MealOption>[]},
  );

  /// This plan with a different week; meals and running are kept.
  UserPlan withWeek(List<WorkoutDay> newWeek) => UserPlan(
    week: newWeek,
    meals: meals,
    runStages: runStages,
    runDays: runDays,
    runWindow: runWindow,
  );

  WorkoutDay workoutFor(DateTime date) => week[date.weekday - 1];

  List<MealOption> options(MealType type) => meals[type] ?? const [];

  bool isPreset(MealType type, String name) {
    final n = name.trim().toLowerCase();
    return options(type).any((o) => o.name.toLowerCase() == n);
  }

  bool get hasRunning => runStages.isNotEmpty;

  /// Running unlocks on the first stage's start date; a plan without
  /// running never unlocks it.
  bool isRunUnlocked(DateTime now) =>
      hasRunning && !now.isBefore(runStages.first.from);

  bool isRunDay(DateTime date) => !hasRunning || runDays.contains(date.weekday);

  /// Latest stage that has started by [date]; later dates hold the last one.
  RunTarget? runTargetFor(DateTime date) {
    if (!isRunUnlocked(date)) return null;
    RunTarget? t;
    for (final s in runStages) {
      if (!date.isBefore(s.from)) t = s.target;
    }
    return t;
  }

  // -------------------------------------------------------------------------
  // JSON
  // -------------------------------------------------------------------------

  Map<String, dynamic> toJson() => {
    'week': [
      for (final d in week)
        {
          'title': d.title,
          'short': d.short,
          'duration': d.duration,
          'exercises': [
            for (final e in d.exercises)
              {
                'name': e.name,
                'sets': e.sets,
                if (e.reps != null) 'reps': e.reps,
                if (e.seconds != null) 'seconds': e.seconds,
                if (e.perSide) 'per_side': true,
              },
          ],
        },
    ],
    'meals': {
      for (final t in MealType.values)
        t.name: [
          for (final o in options(t)) {'name': o.name, 'flagged': o.flagged},
        ],
    },
    if (hasRunning)
      'run': {
        'window': runWindow,
        'days': runDays.toList()..sort(),
        'stages': [
          for (final s in runStages)
            {
              'from': dateKey(s.from),
              'min_km': s.target.minKm,
              'max_km': s.target.maxKm,
              'pace': s.target.pace,
              'note': s.target.note,
            },
        ],
      },
  };

  /// Parses and validates a plan. Throws [FormatException] with a message
  /// meant to be shown to the user, because the JSON came from an LLM and
  /// will occasionally be wrong.
  factory UserPlan.fromJson(Map<String, dynamic> j) {
    final weekRaw = _list(j['week'], 'week');
    if (weekRaw.length != 7) {
      throw FormatException(
        '"week" must have 7 days, Monday first (found ${weekRaw.length}).',
      );
    }
    final week = <WorkoutDay>[];
    for (var i = 0; i < 7; i++) {
      final d = _map(weekRaw[i], 'week[$i]');
      final title = _str(d['title'], 'week[$i].title');
      final exercises = <Exercise>[];
      for (final (k, raw) in _list(
        d['exercises'] ?? [],
        'week[$i].exercises',
      ).indexed) {
        final e = _map(raw, 'week[$i].exercises[$k]');
        final where = 'week[$i].exercises[$k]';
        final sets = _int(e['sets'], '$where.sets');
        final reps = e['reps'] == null ? null : _int(e['reps'], '$where.reps');
        final secs = e['seconds'] == null
            ? null
            : _int(e['seconds'], '$where.seconds');
        if (reps == null && secs == null) {
          throw FormatException('$where needs "reps" or "seconds".');
        }
        if (sets < 1 || sets > 20) {
          throw FormatException('$where.sets must be between 1 and 20.');
        }
        exercises.add(
          Exercise(
            name: _str(e['name'], '$where.name'),
            sets: sets,
            reps: reps,
            seconds: secs,
            perSide: e['per_side'] == true,
          ),
        );
      }
      final short = d['short'] is String && (d['short'] as String).isNotEmpty
          ? d['short'] as String
          : (title.length > 8 ? title.substring(0, 8) : title);
      week.add(
        WorkoutDay(
          title: title,
          short: short,
          duration: d['duration'] is String ? d['duration'] as String : '—',
          exercises: exercises,
        ),
      );
    }
    if (week.every((d) => d.isRest)) {
      throw const FormatException('The plan has no workouts at all.');
    }

    final mealsRaw = _map(j['meals'], 'meals');
    final meals = <MealType, List<MealOption>>{};
    for (final t in MealType.values) {
      final items = _list(mealsRaw[t.name], 'meals.${t.name}');
      final opts = <MealOption>[];
      for (final raw in items) {
        if (raw is String && raw.trim().isNotEmpty) {
          opts.add(MealOption(raw.trim()));
        } else if (raw is Map && raw['name'] is String) {
          opts.add(
            MealOption(
              (raw['name'] as String).trim(),
              flagged: raw['flagged'] == true,
            ),
          );
        } else {
          throw FormatException('Bad item in meals.${t.name}.');
        }
      }
      if (opts.length < 3) {
        throw FormatException('meals.${t.name} needs at least 3 options.');
      }
      meals[t] = opts;
    }

    var stages = <RunStage>[];
    var days = <int>{1, 2, 3, 4, 5, 6};
    var window = '';
    final runRaw = j['run'];
    if (runRaw != null) {
      final r = _map(runRaw, 'run');
      window = r['window'] is String ? r['window'] as String : '';
      if (r['days'] != null) {
        days = {
          for (final d in _list(r['days'], 'run.days')) _int(d, 'run.days'),
        }..removeWhere((d) => d < 1 || d > 7);
      }
      for (final (k, raw) in _list(r['stages'] ?? [], 'run.stages').indexed) {
        final s = _map(raw, 'run.stages[$k]');
        final from = DateTime.tryParse(_str(s['from'], 'run.stages[$k].from'));
        if (from == null) {
          throw FormatException(
            'run.stages[$k].from is not a YYYY-MM-DD date.',
          );
        }
        final minKm = _num(s['min_km'], 'run.stages[$k].min_km');
        final maxKm = _num(s['max_km'], 'run.stages[$k].max_km');
        stages.add(
          RunStage(
            from: DateTime(from.year, from.month, from.day),
            target: RunTarget(
              minKm: minKm,
              maxKm: maxKm < minKm ? minKm : maxKm,
              pace: s['pace'] is String ? s['pace'] as String : '',
              note: s['note'] is String ? s['note'] as String : '',
            ),
          ),
        );
      }
      stages.sort((a, b) => a.from.compareTo(b.from));
    }

    return UserPlan(
      week: week,
      meals: meals,
      runStages: stages,
      runDays: days,
      runWindow: window,
    );
  }
}

List<dynamic> _list(Object? v, String at) =>
    v is List ? v : throw FormatException('"$at" must be a list.');

Map<String, dynamic> _map(Object? v, String at) => v is Map
    ? Map<String, dynamic>.from(v)
    : throw FormatException('"$at" must be an object.');

String _str(Object? v, String at) => v is String && v.trim().isNotEmpty
    ? v.trim()
    : throw FormatException('"$at" must be a non-empty string.');

int _int(Object? v, String at) =>
    v is num ? v.round() : throw FormatException('"$at" must be a number.');

double _num(Object? v, String at) =>
    v is num ? v.toDouble() : throw FormatException('"$at" must be a number.');
