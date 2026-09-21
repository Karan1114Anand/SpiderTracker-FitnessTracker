/// Today's workout — tap a set to mark it done.
///
/// The PRD's "≤3 taps to log" applies hardest here: a set is one tap on a
/// pip, with no confirmation and no dialog. Progress saves on every tap,
/// so closing the app mid-session loses nothing.
library;

import 'package:flutter/material.dart';

import '../main.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/web_shot.dart';
import '../theme/spider_copy.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  /// Exercise name -> sets completed. Seeded from storage on first build,
  /// then held here so a tap repaints instantly rather than waiting on a
  /// database round-trip.
  Map<String, int>? _progress;

  Map<String, int> _seed(WorkoutDay plan, WorkoutLog? log) {
    final m = {for (final e in plan.exercises) e.name: 0};
    for (final p in log?.setsDone ?? const <SetProgress>[]) {
      if (m.containsKey(p.exercise)) m[p.exercise] = p.setsCompleted;
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final text = Theme.of(context).textTheme;

    if (repo.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final plan = repo.todayPlan;
    _progress ??= _seed(plan, repo.todayWorkout);
    final progress = _progress!;

    if (plan.exercises.isEmpty) {
      return _RestDay(plan: plan);
    }

    final totalSets = plan.exercises.fold<int>(0, (s, e) => s + e.sets);
    final doneSets = progress.values.fold<int>(0, (s, v) => s + v);
    final allDone = doneSets >= totalSets;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              SpiderSpace.md,
              SpiderSpace.lg,
              SpiderSpace.md,
              SpiderSpace.md,
            ),
            children: [
              Text(plan.title, style: text.headlineMedium),
              const SizedBox(height: SpiderSpace.xs),
              Text(plan.duration, style: text.bodySmall),
              const SizedBox(height: SpiderSpace.md),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: totalSets == 0 ? 0 : doneSets / totalSets,
                        minHeight: 4,
                        color: allDone
                            ? SpiderColors.positive
                            : SpiderColors.info,
                      ),
                    ),
                  ),
                  const SizedBox(width: SpiderSpace.md),
                  Text('$doneSets of $totalSets sets', style: text.bodySmall),
                ],
              ),
              const SizedBox(height: SpiderSpace.sm),
              for (final e in plan.exercises)
                _ExerciseRow(
                  exercise: e,
                  completed: progress[e.name] ?? 0,
                  onSetTap: (n) => _setCount(repo, plan, e, n),
                ),
            ],
          ),
        ),
        // Pinned, so the action is always under the thumb.
        Container(
          decoration: const BoxDecoration(
            color: SpiderColors.bg,
            border: Border(top: BorderSide(color: SpiderColors.outline)),
          ),
          padding: const EdgeInsets.all(SpiderSpace.md),
          child: SizedBox(
            width: double.infinity,
            child: Builder(
              builder: (ctx) => FilledButton(
                onPressed: allDone
                    ? null
                    : () {
                        WebFx.shoot(ctx);
                        _finishAll(repo, plan);
                      },
                child: Text(
                  allDone ? 'Workout complete' : SpiderCopy.finishWorkout,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Tapping pip [n] sets the count to n+1, or clears back to n when the
  /// pip was already the last one filled — so a mis-tap is undone by
  /// tapping the same pip again rather than hunting for a minus button.
  void _setCount(dynamic repo, WorkoutDay plan, Exercise e, int n) {
    final current = _progress![e.name] ?? 0;
    final next = (current == n + 1) ? n : n + 1;
    setState(() => _progress![e.name] = next);
    _persist(repo, plan);
  }

  void _finishAll(dynamic repo, WorkoutDay plan) {
    setState(() {
      for (final e in plan.exercises) {
        _progress![e.name] = e.sets;
      }
    });
    _persist(repo, plan);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(SpiderCopy.workoutComplete),
          duration: Duration(seconds: 3),
        ),
      );
  }

  void _persist(dynamic repo, WorkoutDay plan) {
    final progress = _progress!;
    final complete = plan.exercises.every(
      (e) => (progress[e.name] ?? 0) >= e.sets,
    );
    repo.saveWorkout(
      progress: [
        for (final entry in progress.entries)
          SetProgress(exercise: entry.key, setsCompleted: entry.value),
      ],
      completed: complete,
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    required this.exercise,
    required this.completed,
    required this.onSetTap,
  });

  final Exercise exercise;
  final int completed;
  final void Function(int index) onSetTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final done = completed >= exercise.sets;

    return Column(
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (done)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.check,
                        size: 18,
                        color: SpiderColors.positive,
                      ),
                    ),
                  Expanded(child: Text(exercise.name, style: text.titleMedium)),
                  Text(exercise.prescription, style: text.bodySmall),
                ],
              ),
              const SizedBox(height: SpiderSpace.sm),
              Row(
                children: [
                  for (var i = 0; i < exercise.sets; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: SpiderSpace.sm),
                      child: _SetPip(
                        index: i,
                        filled: i < completed,
                        onTap: () => onSetTap(i),
                        semanticLabel:
                            'Set ${i + 1} of ${exercise.sets}, '
                            '${exercise.name}',
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A single set. Deliberately large: this is tapped with sweaty hands.
class _SetPip extends StatelessWidget {
  const _SetPip({
    required this.filled,
    required this.onTap,
    required this.semanticLabel,
    required this.index,
  });

  final int index;
  final bool filled;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      checked: filled,
      child: InkWell(
        onTap: () {
          if (!filled) WebFx.shoot(context);
          onTap();
        },
        borderRadius: BorderRadius.circular(SpiderRadius.pip),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? SpiderColors.positive : Colors.transparent,
            border: Border.all(
              color: filled ? SpiderColors.positive : SpiderColors.outline,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(SpiderRadius.pip),
          ),
          child: filled
              ? const Icon(Icons.check, size: 20, color: Colors.white)
              : Text(
                  '${index + 1}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: SpiderColors.textMuted,
                  ),
                ),
        ),
      ),
    );
  }
}

class _RestDay extends StatelessWidget {
  const _RestDay({required this.plan});

  final WorkoutDay plan;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SpiderSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.nightlight_round,
              size: 48,
              color: SpiderColors.textMuted,
            ),
            const SizedBox(height: SpiderSpace.md),
            Text(plan.title, style: text.headlineSmall),
            const SizedBox(height: SpiderSpace.sm),
            Text(
              'Rest is part of the plan. The streak holds.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: SpiderColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
