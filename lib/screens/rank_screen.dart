/// Rank: level, today's points by habit, and the level ladder.
library;

import 'package:flutter/material.dart';

import '../main.dart';
import '../models/badges.dart';
import '../models/game.dart';
import '../theme/app_theme.dart';
import '../widgets/panel.dart';
import '../widgets/web_ring.dart';

class RankScreen extends StatelessWidget {
  const RankScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final text = Theme.of(context).textTheme;
    final level = repo.level;
    final xp = repo.todayXp;
    final total = repo.totalXp;
    final badges = repo.badges;

    final quests = <(IconData, String, String, int, int)>[
      (
        Icons.fitness_center,
        'Workout',
        'Finish today’s sets',
        xp.workout,
        DayXp.maxWorkout,
      ),
      (
        Icons.restaurant_menu,
        'Nutrition',
        'Log meals, rate them honestly',
        xp.food,
        DayXp.maxFood,
      ),
      (
        Icons.water_drop_outlined,
        'Water',
        '3 L for full points',
        xp.water,
        DayXp.maxWater,
      ),
      (
        Icons.bedtime_outlined,
        'Sleep',
        '7+ hours for full points',
        xp.sleep,
        DayXp.maxSleep,
      ),
      (Icons.directions_run, 'Run', 'Log a run', xp.run, DayXp.maxRun),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Rank')),
      body: ListView(
        padding: const EdgeInsets.all(SpiderSpace.md),
        children: [
          Row(
            children: [
              WebRing(
                progress: level.progress,
                label: '${level.number}',
                caption: 'LEVEL',
                size: 104,
              ),
              const SizedBox(width: SpiderSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(level.title, style: text.headlineMedium),
                    const SizedBox(height: 4),
                    Text('$total points total', style: text.bodySmall),
                    const SizedBox(height: SpiderSpace.sm),
                    Text(
                      '${level.xpToNext} points to level ${level.number + 1}',
                      style: text.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: SpiderSpace.lg),
          Panel(
            child: Padding(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Today', style: text.titleSmall),
                      const Spacer(),
                      Text(
                        '${xp.total} / ${DayXp.maxTotal} points',
                        style: text.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: SpiderSpace.md),
                  for (final q in quests)
                    _QuestRow(
                      icon: q.$1,
                      title: q.$2,
                      hint: q.$3,
                      earned: q.$4,
                      max: q.$5,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: SpiderSpace.lg),
          Row(
            children: [
              Text('Badges', style: text.titleLarge),
              const Spacer(),
              Text(
                '${badges.where((b) => b.earned).length} of ${badges.length}',
                style: text.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: SpiderSpace.sm),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: SpiderSpace.sm,
            crossAxisSpacing: SpiderSpace.sm,
            childAspectRatio: 0.82,
            children: [for (final b in badges) _BadgeTile(status: b)],
          ),
          const SizedBox(height: SpiderSpace.lg),
          Text('Levels', style: text.titleLarge),
          const SizedBox(height: SpiderSpace.sm),
          Card(
            child: Column(
              children: [
                for (var n = 1; n <= levelTitles.length; n++) ...[
                  _LevelRow(
                    number: n,
                    title: levelTitle(n),
                    startsAt: xpAtLevel(n),
                    reached: n <= level.number,
                    current: n == level.number,
                  ),
                  if (n < levelTitles.length) const Divider(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({
    required this.icon,
    required this.title,
    required this.hint,
    required this.earned,
    required this.max,
  });

  final IconData icon;
  final String title;
  final String hint;
  final int earned;
  final int max;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final done = earned >= max;
    return Padding(
      padding: const EdgeInsets.only(bottom: SpiderSpace.md),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: done ? SpiderColors.positive : SpiderColors.textMuted,
          ),
          const SizedBox(width: SpiderSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: text.titleMedium),
                    const Spacer(),
                    Text('$earned / $max', style: text.bodySmall),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: max == 0 ? 0 : (earned / max).clamp(0, 1),
                    minHeight: 5,
                    color: done ? SpiderColors.positive : SpiderColors.info,
                  ),
                ),
                const SizedBox(height: 4),
                Text(hint, style: text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelRow extends StatelessWidget {
  const _LevelRow({
    required this.number,
    required this.title,
    required this.startsAt,
    required this.reached,
    required this.current,
  });

  final int number;
  final String title;
  final int startsAt;
  final bool reached;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = reached ? null : SpiderColors.textMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SpiderSpace.md,
        vertical: 12,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$number',
              style: text.titleMedium?.copyWith(color: muted),
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: text.bodyLarge?.copyWith(
                color: muted,
                fontWeight: current ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          if (current)
            Text(
              'Current',
              style: text.labelMedium?.copyWith(color: SpiderColors.accent),
            )
          else if (reached)
            const Icon(Icons.check, size: 18, color: SpiderColors.positive)
          else
            Text('$startsAt pts', style: text.bodySmall),
        ],
      ),
    );
  }
}

const Map<String, IconData> _badgeIcons = {
  'first_workout': Icons.fitness_center,
  'streak_3': Icons.local_fire_department_outlined,
  'streak_7': Icons.date_range,
  'streak_14': Icons.local_fire_department,
  'streak_30': Icons.workspace_premium,
  'water_day': Icons.water_drop,
  'water_week': Icons.waves,
  'sleep_night': Icons.bedtime,
  'sleep_week': Icons.nights_stay,
  'diet_day': Icons.restaurant,
  'diet_week': Icons.eco,
  'run_first': Icons.directions_run,
  'run_5': Icons.repeat,
  'run_50km': Icons.route,
  'perfect_day': Icons.star,
  'level_5': Icons.trending_up,
  'level_10': Icons.military_tech,
  'weight_1': Icons.monitor_weight,
  'weight_half': Icons.flag,
  'weight_goal': Icons.emoji_events,
};

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.status});

  final BadgeStatus status;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final earned = status.earned;
    final colour = earned ? SpiderColors.accent : SpiderColors.textMuted;

    return Semantics(
      label:
          '${status.name}. ${status.description} '
          '${earned ? 'Earned.' : 'Locked, ${status.progressLabel}.'}',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: SpiderRadius.cardAll,
        onTap: () => showDialog<void>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(status.name),
            content: Text(
              '${status.description}\n\n'
              '${earned ? 'Earned.' : 'Progress: ${status.progressLabel}'}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            color: SpiderColors.surface,
            borderRadius: SpiderRadius.cardAll,
            border: Border.all(
              color: earned
                  ? SpiderColors.accent.withValues(alpha: 0.6)
                  : SpiderColors.outline,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: earned
                        ? SpiderColors.accent.withValues(alpha: 0.16)
                        : SpiderColors.surfaceHigh,
                  ),
                  child: Icon(
                    earned
                        ? (_badgeIcons[status.id] ?? Icons.star)
                        : Icons.lock_outline,
                    size: 22,
                    color: colour,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  status.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelLarge?.copyWith(
                    color: earned ? null : SpiderColors.textMuted,
                  ),
                ),
                if (!earned) ...[
                  const SizedBox(height: 2),
                  Text(status.progressLabel, style: text.bodySmall),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
