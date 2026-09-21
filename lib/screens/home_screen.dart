/// Home: today at a glance. A web chart of the five daily habits leads;
/// below it, one row per habit with its points, then a quiet summary strip.
library;

import 'package:flutter/material.dart';

import '../main.dart';
import '../models/game.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../theme/spider_copy.dart';
import '../widgets/figure.dart';
import '../widgets/web_radar.dart';
import '../widgets/web_shot.dart';
import 'profile_screen.dart';
import 'rank_screen.dart';
import 'weight_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String _greeting(DateTime now) => now.hour < 12
      ? 'Good morning'
      : now.hour < 18
      ? 'Good afternoon'
      : 'Good evening';

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final text = Theme.of(context).textTheme;

    if (repo.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final now = DateTime.now();
    final xp = repo.todayXp;
    final level = repo.level;
    final plan = repo.todayPlan;
    final name = repo.profile?.name.split(' ').first;
    final w = repo.todayWellness;
    final run = repo.todayRun;
    final remaining = repo.remainingKg;
    final weight = repo.latestWeightKg;

    final logged =
        repo.todayWorkout?.setsDone.fold<int>(
          0,
          (s, p) => s + p.setsCompleted,
        ) ??
        0;
    final totalSets = plan.exercises.fold<int>(0, (s, e) => s + e.sets);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SpiderSpace.md,
        SpiderSpace.md,
        SpiderSpace.md,
        SpiderSpace.xl,
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_weekdays[now.weekday - 1]} ${now.day} '
                    '${_months[now.month - 1]}',
                    style: text.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name == null ? _greeting(now) : '${_greeting(now)}, $name',
                    style: text.headlineMedium,
                  ),
                ],
              ),
            ),
            _ProfileButton(name: name),
          ],
        ),
        const SizedBox(height: SpiderSpace.md),

        WebRadar(
          points: xp.total,
          maxPoints: DayXp.maxTotal,
          axes: [
            RadarAxis('Workout', xp.workout / DayXp.maxWorkout),
            RadarAxis('Food', xp.food / DayXp.maxFood),
            RadarAxis('Water', xp.water / DayXp.maxWater),
            RadarAxis('Sleep', xp.sleep / DayXp.maxSleep),
            RadarAxis('Run', xp.run / DayXp.maxRun),
          ],
        ),

        _LevelLine(level: level),
        const SizedBox(height: SpiderSpace.lg),

        _HabitRow(
          icon: Icons.fitness_center_outlined,
          title: plan.isRest ? 'Rest day' : plan.title,
          detail: plan.isRest
              ? 'Recovery is part of the plan'
              : '$logged of $totalSets sets',
          earned: xp.workout,
          max: DayXp.maxWorkout,
          onTap: () => TabSwitcher.of(context)(1),
        ),
        _HabitRow(
          icon: Icons.restaurant_menu_outlined,
          title: 'Meals',
          detail: '${repo.todayMeals.length} of 4 logged',
          earned: xp.food,
          max: DayXp.maxFood,
          onTap: () => TabSwitcher.of(context)(2),
        ),
        _HabitRow(
          icon: Icons.water_drop_outlined,
          title: 'Water',
          detail:
              '${(w.waterMl / 1000).toStringAsFixed(2)} of '
              '${(WellnessLog.waterGoalMl / 1000).toStringAsFixed(0)} L',
          earned: xp.water,
          max: DayXp.maxWater,
          controls: _Stepper(
            onMinus: () => repo.addWater(-1),
            onPlus: () => repo.addWater(1),
            label: 'water',
          ),
        ),
        _HabitRow(
          icon: Icons.bedtime_outlined,
          title: 'Sleep',
          detail: w.sleepHours == null
              ? SpiderCopy.noSleepYet
              : '${w.sleepHours!.toStringAsFixed(1)} hours',
          earned: xp.sleep,
          max: DayXp.maxSleep,
          controls: _Stepper(
            onMinus: () => repo.setSleep((w.sleepHours ?? 8) - 0.5),
            onPlus: () => repo.setSleep((w.sleepHours ?? 7.5) + 0.5),
            label: 'sleep',
          ),
        ),
        _HabitRow(
          icon: Icons.directions_run,
          title: 'Run',
          detail: run == null
              ? 'Not logged'
              : '${run.distanceKm.toStringAsFixed(1)} km',
          earned: xp.run,
          max: DayXp.maxRun,
          onTap: () => TabSwitcher.of(context)(3),
          last: true,
        ),

        const SizedBox(height: SpiderSpace.lg),
        Row(
          children: [
            Figure(
              value: weight?.toStringAsFixed(1) ?? '—',
              label: 'Weight (kg)',
              onTap: () => openWeighIn(context),
            ),
            Figure(
              value: remaining == null
                  ? '—'
                  : (remaining <= 0 ? '0' : remaining.toStringAsFixed(1)),
              label: 'To goal (kg)',
            ),
            Figure(
              value: '${repo.daysToGoal < 0 ? 0 : repo.daysToGoal}',
              label: 'Days left',
            ),
            Figure(
              value: '${repo.state.currentStreak}',
              label: 'Streak (days)',
            ),
          ],
        ),

        if (repo.weighInDue) ...[
          const SizedBox(height: SpiderSpace.lg),
          Row(
            children: [
              Expanded(
                child: Text(SpiderCopy.mondayWeighIn, style: text.bodyMedium),
              ),
              TextButton(
                onPressed: () => openWeighIn(context),
                child: const Text('Weigh in'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final initial = (name != null && name!.isNotEmpty)
        ? name![0].toUpperCase()
        : '?';
    return Semantics(
      button: true,
      label: 'Profile',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: SpiderColors.surfaceHigh,
            border: Border.all(color: SpiderColors.outline),
          ),
          child: Text(initial, style: Theme.of(context).textTheme.titleMedium),
        ),
      ),
    );
  }
}

/// "Level 3  Web-Slinger" with points to the next level and a thin bar.
class _LevelLine extends StatelessWidget {
  const _LevelLine({required this.level});

  final Level level;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const RankScreen())),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: SpiderSpace.sm),
        child: Column(
          children: [
            Row(
              children: [
                Text('Level ${level.number}', style: text.titleMedium),
                const SizedBox(width: SpiderSpace.sm),
                Text(level.title, style: text.bodyMedium),
                const Spacer(),
                Text('${level.xpToNext} to next', style: text.bodySmall),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: SpiderColors.textMuted,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: level.progress,
                minHeight: 4,
                color: SpiderColors.info,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One daily habit: what it is, where it stands, and the points it earned.
class _HabitRow extends StatelessWidget {
  const _HabitRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.earned,
    required this.max,
    this.onTap,
    this.controls,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String detail;
  final int earned;
  final int max;
  final VoidCallback? onTap;
  final Widget? controls;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final done = earned >= max;

    return Column(
      children: [
        const Divider(),
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 22, color: SpiderColors.textMuted),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: text.titleMedium),
                      const SizedBox(height: 2),
                      Text(detail, style: text.bodySmall),
                    ],
                  ),
                ),
                if (controls != null) controls!,
                SizedBox(
                  width: 52,
                  child: Text(
                    '$earned/$max',
                    textAlign: TextAlign.right,
                    style: text.bodySmall?.copyWith(
                      color: done
                          ? SpiderColors.positive
                          : SpiderColors.textMuted,
                      fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (last) const Divider(),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.onMinus,
    required this.onPlus,
    required this.label,
  });

  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Less $label',
          onPressed: onMinus,
          visualDensity: VisualDensity.compact,
          icon: const Icon(
            Icons.remove_circle_outline,
            color: SpiderColors.textMuted,
          ),
        ),
        Builder(
          builder: (ctx) => IconButton(
            tooltip: 'More $label',
            onPressed: () {
              WebFx.shoot(ctx);
              onPlus();
            },
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ),
      ],
    );
  }
}
