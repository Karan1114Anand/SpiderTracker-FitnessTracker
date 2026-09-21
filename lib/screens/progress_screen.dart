/// Progress: weight trend, workout consistency, diet history.
///
/// The trend is drawn against a band of 0.5-0.75 kg/week, the range that is
/// sustainable, with the user's goal weight as a dashed line. Inside the
/// band is on track. The band is anchored to the first recorded weigh-in so
/// starting late isn't penalised for days that weren't tracked.
library;

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../models/models.dart';
import '../models/user_plan.dart';
import '../theme/app_theme.dart';
import '../models/badges.dart' show longestWorkoutStreak;
import '../widgets/figure.dart';
import '../widgets/panel.dart';
import 'weight_screen.dart';
import '../theme/spider_copy.dart';

/// Weekly loss rates the band is drawn from.
const double _kRealisticSlowKgPerWeek = 0.5;
const double _kRealisticFastKgPerWeek = 0.75;

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final text = Theme.of(context).textTheme;

    if (repo.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final weights = repo.weights;
    final workouts = repo.allWorkouts;
    final now = DateTime.now();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SpiderSpace.md,
        SpiderSpace.lg,
        SpiderSpace.md,
        SpiderSpace.xl,
      ),
      children: [
        Text('Progress', style: text.displaySmall),
        const SizedBox(height: SpiderSpace.xs),
        Text(
          SpiderCopy.daysToGoal(repo.daysToGoal),
          style: text.bodyMedium?.copyWith(color: SpiderColors.textMuted),
        ),
        const SizedBox(height: SpiderSpace.lg),

        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => openWeighIn(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: SpiderSpace.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    repo.latestWeightKg == null
                        ? 'No weigh-in yet'
                        : 'Latest weigh-in  ${repo.latestWeightKg!.toStringAsFixed(1)} kg',
                    style: text.titleMedium,
                  ),
                ),
                Text(
                  'Log weigh-in',
                  style: text.labelLarge?.copyWith(color: SpiderColors.accent),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: SpiderColors.textMuted,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: SpiderSpace.md),

        _TrendCard(
          weights: weights,
          goalWeight: repo.state.goalWeight,
          goalDate: parseDateKey(repo.state.goalDate),
          now: now,
        ),
        const SizedBox(height: SpiderSpace.lg),

        Row(
          children: [
            Figure(
              value: '${workouts.where((w) => w.completed).length}',
              label: 'Workouts done',
            ),
            Figure(
              value: '${repo.state.currentStreak}',
              label: 'Streak (days)',
            ),
            Figure(
              value: '${longestWorkoutStreak(workouts)}',
              label: 'Best streak',
            ),
          ],
        ),
        const SizedBox(height: SpiderSpace.lg),

        Text('Consistency', style: text.titleLarge),
        const SizedBox(height: SpiderSpace.sm),
        _WorkoutHeatmap(workouts: workouts, now: now, plan: repo.plan),
        const SizedBox(height: SpiderSpace.lg),

        Text(SpiderCopy.webStrengthTitle, style: text.titleLarge),
        const SizedBox(height: SpiderSpace.sm),
        _DietHistory(scores: repo.dietScores),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Weight trend
// ---------------------------------------------------------------------------

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.weights,
    required this.goalWeight,
    required this.goalDate,
    required this.now,
  });

  final List<WeightLog> weights;
  final double goalWeight;
  final DateTime goalDate;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    if (weights.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(SpiderSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Weight trend', style: text.titleMedium),
              const SizedBox(height: SpiderSpace.sm),
              Text(SpiderCopy.noWeightYet, style: text.bodySmall),
              const SizedBox(height: SpiderSpace.sm),
              Text(
                'Log a Monday weigh-in and the line starts here.',
                style: text.bodyMedium?.copyWith(color: SpiderColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    final anchor = parseDateKey(weights.first.date);
    final anchorKg = weights.first.weightKg;
    final spanDays = math.max(
      goalDate.difference(anchor).inDays.toDouble(),
      7.0,
    );

    double x(DateTime d) => d.difference(anchor).inDays.toDouble();

    final actual = [
      for (final w in weights) FlSpot(x(parseDateKey(w.date)), w.weightKg),
    ];

    // Band edges, straight lines from the first reading to the goal date.
    final slowEnd = anchorKg - _kRealisticSlowKgPerWeek * spanDays / 7;
    final fastEnd = anchorKg - _kRealisticFastKgPerWeek * spanDays / 7;
    final slow = [FlSpot(0, anchorKg), FlSpot(spanDays, slowEnd)];
    final fast = [FlSpot(0, anchorKg), FlSpot(spanDays, fastEnd)];
    final stretch = [FlSpot(0, goalWeight), FlSpot(spanDays, goalWeight)];

    final lowest = <double>[
      goalWeight,
      fastEnd,
      ...weights.map((w) => w.weightKg),
    ].reduce(math.min);
    final highest = <double>[
      anchorKg,
      ...weights.map((w) => w.weightKg),
    ].reduce(math.max);

    return Panel(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weight trend', style: text.titleMedium),
            const SizedBox(height: SpiderSpace.xs),
            Text(
              _verdict(weights, anchor, anchorKg, now),
              style: text.bodyMedium?.copyWith(color: SpiderColors.textPrimary),
            ),
            const SizedBox(height: SpiderSpace.md),
            SizedBox(
              height: 210,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: spanDays,
                  minY: lowest - 1.5,
                  maxY: highest + 1.5,
                  lineTouchData: const LineTouchData(enabled: false),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 2,
                    getDrawingHorizontalLine: (_) => const FlLine(
                      color: SpiderColors.outline,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 2,
                        reservedSize: 34,
                        getTitlesWidget: (value, _) => value % 2 != 0
                            ? const SizedBox.shrink()
                            : Text(
                                value.toStringAsFixed(0),
                                style: text.labelSmall,
                              ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: math.max(spanDays / 4, 7),
                        reservedSize: 26,
                        getTitlesWidget: (value, meta) =>
                            value > meta.max - spanDays * 0.08
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(
                                  top: SpiderSpace.xs,
                                ),
                                child: Text(
                                  _shortDate(
                                    anchor.add(Duration(days: value.round())),
                                  ),
                                  style: text.labelSmall,
                                ),
                              ),
                      ),
                    ),
                  ),
                  betweenBarsData: [
                    BetweenBarsData(
                      fromIndex: 0,
                      toIndex: 1,
                      color: SpiderColors.surfaceHigh.withValues(alpha: 0.45),
                    ),
                  ],
                  lineBarsData: [
                    // 0 and 1 are the band edges; the fill sits between them.
                    _bandLine(slow),
                    _bandLine(fast),
                    LineChartBarData(
                      spots: stretch,
                      color: SpiderColors.caution.withValues(alpha: 0.8),
                      barWidth: 1.4,
                      dashArray: const [6, 5],
                      dotData: const FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: actual,
                      color: SpiderColors.info,
                      barWidth: 2.6,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: SpiderSpace.md),
            _Legend(goalWeight: goalWeight),
            const SizedBox(height: SpiderSpace.sm),
            Text(
              _projection(weights, goalWeight, goalDate),
              style: text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  LineChartBarData _bandLine(List<FlSpot> spots) => LineChartBarData(
    spots: spots,
    color: SpiderColors.surfaceHigh,
    barWidth: 1,
    dotData: const FlDotData(show: false),
  );

  /// Where he sits against the realistic band, phrased for a person.
  String _verdict(
    List<WeightLog> weights,
    DateTime anchor,
    double anchorKg,
    DateTime now,
  ) {
    if (weights.length < 2) return 'Log one more weigh-in to see your trend.';

    final latest = weights.last;
    final weeks = math.max(
      parseDateKey(latest.date).difference(anchor).inDays / 7,
      0.001,
    );
    final lost = anchorKg - latest.weightKg;
    final rate = lost / weeks;

    if (rate >= _kRealisticFastKgPerWeek * 1.2) {
      return 'Losing ${rate.toStringAsFixed(2)} kg a week, faster than '
          'planned. Make sure you are still eating enough.';
    }
    if (rate >= _kRealisticSlowKgPerWeek) {
      return 'Losing ${rate.toStringAsFixed(2)} kg a week. On track.';
    }
    if (rate > 0) {
      return 'Losing ${rate.toStringAsFixed(2)} kg a week. Slower than '
          'planned, but moving the right way.';
    }
    return 'No change yet. Weight moves in steps, so keep logging.';
  }

  /// Straight-line projection from the observed rate to the goal date.
  String _projection(
    List<WeightLog> weights,
    double goalWeight,
    DateTime goalDate,
  ) {
    if (weights.length < 2) {
      return 'A projection needs two weigh-ins.';
    }
    final first = weights.first;
    final last = weights.last;
    final days = parseDateKey(
      last.date,
    ).difference(parseDateKey(first.date)).inDays;
    if (days <= 0) return 'A projection needs two weigh-ins.';

    final perDay = (last.weightKg - first.weightKg) / days;
    final daysLeft = goalDate.difference(parseDateKey(last.date)).inDays;
    if (daysLeft <= 0) return 'Goal date reached.';

    final projected = last.weightKg + perDay * daysLeft;
    if (projected <= goalWeight) {
      return 'At this rate: ${projected.toStringAsFixed(1)} kg by the goal '
          'date. You are on course for your goal.';
    }
    return 'At this rate: ${projected.toStringAsFixed(1)} kg by the goal '
        'date. Your goal is ${goalWeight.toStringAsFixed(1)} kg.';
  }

  static String _shortDate(DateTime d) {
    const months = [
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
    return '${d.day} ${months[d.month - 1]}';
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.goalWeight});

  final double goalWeight;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: SpiderSpace.md,
      runSpacing: SpiderSpace.xs,
      children: [
        const _LegendDot(colour: SpiderColors.info, label: 'You'),
        const _LegendDot(
          colour: SpiderColors.textMuted,
          label: 'Expected range',
        ),
        _LegendDot(
          colour: SpiderColors.caution,
          label: '${goalWeight.toStringAsFixed(1)} kg goal',
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.colour, required this.label});

  final Color colour;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
        ),
        const SizedBox(width: SpiderSpace.xs),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Consistency
// ---------------------------------------------------------------------------

/// Twelve weeks of workout days, one square each: gold for a completed
/// day, dim gold for one part-logged, navy for a prescribed rest day.
class _WorkoutHeatmap extends StatelessWidget {
  const _WorkoutHeatmap({
    required this.workouts,
    required this.now,
    required this.plan,
  });

  final UserPlan plan;
  final List<WorkoutLog> workouts;
  final DateTime now;

  static const int _weeks = 12;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final byDate = {for (final w in workouts) w.date: w};

    // Start on the Monday 11 weeks before this week's Monday.
    final thisMonday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - DateTime.monday));
    final start = thisMonday.subtract(const Duration(days: (_weeks - 1) * 7));

    return Panel(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, box) {
                // Cells grow to fill the width, so the grid spans the screen.
                final cell = ((box.maxWidth - 4 * (_weeks - 1)) / _weeks).clamp(
                  10.0,
                  40.0,
                );
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var week = 0; week < _weeks; week++)
                      Column(
                        children: [
                          for (var day = 0; day < 7; day++)
                            _HeatCell(
                              date: start.add(Duration(days: week * 7 + day)),
                              log:
                                  byDate[dateKey(
                                    start.add(Duration(days: week * 7 + day)),
                                  )],
                              now: now,
                              size: cell,
                              rest: plan
                                  .workoutFor(
                                    start.add(Duration(days: week * 7 + day)),
                                  )
                                  .isRest,
                            ),
                        ],
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: SpiderSpace.sm),
            Text(
              workouts.isEmpty
                  ? SpiderCopy.noStreakYet
                  : 'Last 12 weeks. Each square is a day.',
              style: text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeatCell extends StatelessWidget {
  const _HeatCell({
    required this.date,
    required this.log,
    required this.now,
    required this.rest,
    required this.size,
  });

  final double size;
  final bool rest;

  final DateTime date;
  final WorkoutLog? log;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final future = date.isAfter(DateTime(now.year, now.month, now.day));

    final Color colour;
    if (future) {
      colour = Colors.transparent;
    } else if (log?.completed ?? false) {
      colour = SpiderColors.info;
    } else if (log != null) {
      colour = SpiderColors.info.withValues(alpha: 0.35);
    } else if (rest) {
      colour = SpiderColors.surfaceHigh;
    } else {
      colour = SpiderColors.surfaceHigh;
    }

    return Semantics(
      label:
          '${dateKey(date)}: '
          '${(log?.completed ?? false)
              ? 'completed'
              : log != null
              ? 'partly logged'
              : rest
              ? 'rest day'
              : 'no workout'}',
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: colour,
          borderRadius: BorderRadius.circular(3),
          border: future
              ? Border.all(color: SpiderColors.outline, width: 0.8)
              : null,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Diet history
// ---------------------------------------------------------------------------

/// Daily diet scores as small vertical bars, newest last. Renders whatever
/// map of dateKey -> score it is given.
class _DietHistory extends StatelessWidget {
  const _DietHistory({required this.scores});

  final Map<String, int> scores;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final keys = scores.keys.toList()..sort();
    final anyLogged = scores.values.any((s) => s > 0);

    return Panel(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!anyLogged)
              Text(SpiderCopy.noMealsYet, style: text.bodySmall)
            else ...[
              SizedBox(
                height: 74,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final key in keys)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _ScoreBar(score: scores[key] ?? 0, label: key),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: SpiderSpace.sm),
              Text(
                'Out of 8 a day. Taller is a better day.',
                style: text.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.score, required this.label});

  final int score;
  final String label;

  @override
  Widget build(BuildContext context) {
    final fraction = (score / 8).clamp(0.0, 1.0);
    return Semantics(
      label: '$label: $score of 8',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 14,
            height: 56 * fraction + 2,
            decoration: BoxDecoration(
              color: Color.lerp(SpiderColors.info, SpiderColors.info, fraction),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: SpiderSpace.xs),
          Text(
            label.substring(label.length - 2),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
