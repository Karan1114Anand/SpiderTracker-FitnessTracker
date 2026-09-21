/// Runs: today's target, entry, streak and history.
///
/// Always available. When the plan has a running ladder the target card
/// shows it; otherwise this is a free log of distance and time.
///
/// Two taps and two numbers to log: distance, duration, Log run.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/workout_plan.dart';
import '../main.dart';
import '../models/models.dart';
import '../models/user_plan.dart';
import '../services/repository.dart';
import '../theme/app_theme.dart';
import '../widgets/figure.dart';
import '../widgets/web_shot.dart';

class RunScreen extends StatefulWidget {
  const RunScreen({super.key});

  @override
  State<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends State<RunScreen> {
  final TextEditingController _km = TextEditingController();
  final TextEditingController _min = TextEditingController();
  final FocusNode _kmFocus = FocusNode();
  final FocusNode _minFocus = FocusNode();

  /// True while re-entering a run that is already logged for today.
  bool _editing = false;

  @override
  void dispose() {
    _km.dispose();
    _min.dispose();
    _kmFocus.dispose();
    _minFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final text = Theme.of(context).textTheme;

    if (repo.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final now = DateTime.now();
    final target = repo.plan.runTargetFor(now);
    final restDay = !repo.plan.isRunDay(now);
    final today = repo.todayRun;

    final runs = repo.runs;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SpiderSpace.md,
        SpiderSpace.lg,
        SpiderSpace.md,
        SpiderSpace.xl,
      ),
      children: [
        Text('Runs', style: text.displaySmall),
        Text(
          restDay
              ? 'Rest day'
              : (repo.plan.runWindow.isEmpty ? 'Today' : repo.plan.runWindow),
          style: text.bodyMedium?.copyWith(color: SpiderColors.textMuted),
        ),
        const SizedBox(height: SpiderSpace.lg),

        if (target != null && !restDay) _TargetCard(target: target),
        if (restDay) Text('No run scheduled today.', style: text.bodyMedium),
        const SizedBox(height: SpiderSpace.md),

        if (today != null && !_editing)
          _LoggedRunCard(run: today, onEdit: () => _seedForEdit(today))
        else
          _RunEntry(
            km: _km,
            min: _min,
            kmFocus: _kmFocus,
            minFocus: _minFocus,
            onSubmit: () => _save(repo),
          ),
        const SizedBox(height: SpiderSpace.lg),

        Row(
          children: [
            Figure(
              value: '${_runStreak(runs, now, repo.plan)}',
              label: 'Run streak (days)',
            ),
            Figure(value: '${runs.length}', label: 'Runs logged'),
            Figure(
              value: repo.runs
                  .fold<double>(0, (s, r) => s + r.distanceKm)
                  .toStringAsFixed(1),
              label: 'Total km',
            ),
          ],
        ),
        const SizedBox(height: SpiderSpace.lg),

        Text('Recent runs', style: text.titleLarge),
        const SizedBox(height: SpiderSpace.sm),
        if (runs.isEmpty)
          Text(
            'Nothing logged yet. The first one is the hard one.',
            style: text.bodySmall,
          )
        else
          for (final run in runs.reversed) _RunRow(run: run),
      ],
    );
  }

  /// Consecutive days with a logged run, counting back from today (or
  /// yesterday, if today's run is still to come). Days the plan
  /// doesn't schedule a run are skipped rather than breaking the chain.
  int _runStreak(List<RunLog> runs, DateTime now, UserPlan plan) {
    if (runs.isEmpty) return 0;
    final logged = runs.map((r) => r.date).toSet();
    var cursor = DateTime(now.year, now.month, now.day);
    if (!logged.contains(dateKey(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (true) {
      if (!plan.isRunDay(cursor)) {
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }
      if (!logged.contains(dateKey(cursor))) break;
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  void _seedForEdit(RunLog run) {
    setState(() {
      _editing = true;
      _km.text = run.distanceKm.toString();
      _min.text = run.durationMin.toString();
    });
    _kmFocus.requestFocus();
  }

  void _save(AppRepository repo) {
    final km = double.tryParse(_km.text.trim());
    final min = int.tryParse(_min.text.trim());
    if (km == null || km <= 0 || min == null || min <= 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Need a distance and a time to work out a pace.'),
            duration: Duration(seconds: 2),
          ),
        );
      return;
    }
    FocusScope.of(context).unfocus();
    WebFx.shoot(context);
    repo.saveRun(distanceKm: km, durationMin: min);
    _km.clear();
    _min.clear();
    setState(() => _editing = false);
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({required this.target});

  final RunTarget target;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Today's target", style: text.bodySmall),
        const SizedBox(height: SpiderSpace.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(target.distanceLabel, style: text.displayMedium),
            const SizedBox(width: SpiderSpace.sm),
            Text(target.pace, style: text.bodyMedium),
          ],
        ),
        const SizedBox(height: SpiderSpace.xs),
        Text(target.note, style: text.bodySmall),
      ],
    );
  }
}

/// Distance and duration. Two fields, one button, no dialog.
class _RunEntry extends StatelessWidget {
  const _RunEntry({
    required this.km,
    required this.min,
    required this.kmFocus,
    required this.minFocus,
    required this.onSubmit,
  });

  final TextEditingController km;
  final TextEditingController min;
  final FocusNode kmFocus;
  final FocusNode minFocus;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    controller: km,
                    focusNode: kmFocus,
                    label: 'Distance',
                    suffix: 'km',
                    decimal: true,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => minFocus.requestFocus(),
                  ),
                ),
                const SizedBox(width: SpiderSpace.md),
                Expanded(
                  child: _NumberField(
                    controller: min,
                    focusNode: minFocus,
                    label: 'Duration',
                    suffix: 'min',
                    decimal: false,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => onSubmit(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpiderSpace.md),
            FilledButton(onPressed: onSubmit, child: const Text('Log run')),
          ],
        ),
      ],
    );
  }
}

/// Numeric input with the right keyboard and no focus traps: every field
/// submits to the next one, and the last one submits the form.
class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.suffix,
    required this.decimal,
    required this.textInputAction,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String suffix;
  final bool decimal;
  final TextInputAction textInputAction;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          decimal ? RegExp(r'[0-9.]') : RegExp(r'[0-9]'),
        ),
      ],
      style: Theme.of(context).textTheme.headlineSmall,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        filled: true,
        fillColor: SpiderColors.bg,
        border: const OutlineInputBorder(
          borderRadius: SpiderRadius.cardAll,
          borderSide: BorderSide(color: SpiderColors.outline),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: SpiderRadius.cardAll,
          borderSide: BorderSide(color: SpiderColors.outline),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: SpiderRadius.cardAll,
          borderSide: BorderSide(color: SpiderColors.accent, width: 1.6),
        ),
      ),
    );
  }
}

class _LoggedRunCard extends StatelessWidget {
  const _LoggedRunCard({required this.run, required this.onEdit});

  final RunLog run;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: SpiderSpace.md),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: SpiderColors.positive),
              const SizedBox(width: SpiderSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${run.distanceKm.toStringAsFixed(1)} km in ${run.durationMin} min',
                      style: text.titleMedium,
                    ),
                    Text(run.paceLabel, style: text.bodySmall),
                  ],
                ),
              ),
              TextButton(onPressed: onEdit, child: const Text('Edit')),
            ],
          ),
        ),
        const Divider(),
      ],
    );
  }
}

class _RunRow extends StatelessWidget {
  const _RunRow({required this.run});

  final RunLog run;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpiderSpace.sm),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            child: Text(prettyDateKey(run.date), style: text.bodySmall),
          ),
          Expanded(
            child: Text(
              '${run.distanceKm.toStringAsFixed(1)} km',
              style: text.bodyMedium,
            ),
          ),
          Text(
            run.paceLabel,
            style: text.bodySmall?.copyWith(color: SpiderColors.textMuted),
          ),
        ],
      ),
    );
  }
}
