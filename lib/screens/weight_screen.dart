/// Weigh-in — Mondays only, one number, one tap.
///
/// The PRD makes weight a weekly ritual rather than a daily one: daily
/// weighing on a cut is mostly water noise, and the app should not invite
/// it. So on any other day this screen shows the last reading and when the
/// next is due, with no input to fiddle with.
///
/// One deliberate exception: a fresh install with no weight at all can
/// record a baseline on any day. Otherwise someone installing on a Tuesday
/// stares at an empty app for six days. Flagged to J.A.R.V.I.S.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../models/models.dart';
import '../services/repository.dart';
import '../theme/app_theme.dart';
import '../widgets/figure.dart';
import '../widgets/panel.dart';
import '../theme/spider_copy.dart';

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  final TextEditingController _kg = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _kg.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final text = Theme.of(context).textTheme;

    if (repo.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final weights = repo.weights;
    final latest = weights.isEmpty ? null : weights.last;
    final baseline = weights.isEmpty;
    final loggedToday = weights.any((w) => w.date == repo.today);
    final showEntry = repo.weighInDue || baseline;
    final atGoal = latest != null && latest.weightKg <= repo.state.goalWeight;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SpiderSpace.md,
        SpiderSpace.lg,
        SpiderSpace.md,
        SpiderSpace.xl,
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Text('Weigh-in', style: text.displaySmall),
        Text(
          'Started at ${repo.state.startWeight.toStringAsFixed(1)} kg, '
          'goal ${repo.state.goalWeight.toStringAsFixed(1)} kg',
          style: text.bodySmall,
        ),
        const SizedBox(height: SpiderSpace.lg),

        if (atGoal) ...[
          const _GoalBanner(),
          const SizedBox(height: SpiderSpace.md),
        ],

        Row(
          children: [
            Figure(
              value: latest?.weightKg.toStringAsFixed(1) ?? '—',
              label: 'Current (kg)',
            ),
            Figure(
              value: latest == null
                  ? '—'
                  : (repo.state.startWeight - latest.weightKg).toStringAsFixed(
                      1,
                    ),
              label: 'Lost so far (kg)',
            ),
            Figure(
              value: latest == null
                  ? '—'
                  : (latest.weightKg - repo.state.goalWeight)
                        .clamp(0, double.infinity)
                        .toStringAsFixed(1),
              label: 'To go (kg)',
            ),
          ],
        ),
        const SizedBox(height: SpiderSpace.lg),

        if (showEntry)
          _WeightEntry(
            controller: _kg,
            focusNode: _focus,
            baseline: baseline,
            onSubmit: () => _save(repo),
          )
        else if (loggedToday)
          _LoggedTodayCard(
            entry: latest!,
            delta: _deltaOf(weights, weights.length - 1),
          )
        else
          _NextDueCard(latest: latest),

        const SizedBox(height: SpiderSpace.lg),
        Text('History', style: text.titleLarge),
        const SizedBox(height: SpiderSpace.sm),
        if (weights.isEmpty)
          Text(SpiderCopy.noWeightYet, style: text.bodySmall)
        else
          for (var i = weights.length - 1; i >= 0; i--)
            _WeightRow(entry: weights[i], delta: _deltaOf(weights, i)),
      ],
    );
  }

  /// Change against the previous entry, or null for the first one.
  double? _deltaOf(List<WeightLog> weights, int index) =>
      index <= 0 ? null : weights[index].weightKg - weights[index - 1].weightKg;

  void _save(AppRepository repo) {
    final kg = double.tryParse(_kg.text.trim());
    if (kg == null || kg < 30 || kg > 250) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('That does not look like a body weight in kg.'),
            duration: Duration(seconds: 2),
          ),
        );
      return;
    }
    FocusScope.of(context).unfocus();
    final previous = repo.latestWeightKg;
    repo.saveWeight(kg);
    _kg.clear();

    final message = kg <= repo.state.goalWeight
        ? SpiderCopy.goalWeightReached
        : previous == null
        ? 'Baseline set. Everything from here is progress.'
        : SpiderCopy.weighInResult(kg - previous);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
  }
}

class _WeightEntry extends StatelessWidget {
  const _WeightEntry({
    required this.controller,
    required this.focusNode,
    required this.baseline,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool baseline;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Panel(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              baseline ? 'Set your starting weight' : SpiderCopy.mondayWeighIn,
              style: text.titleMedium,
            ),
            const SizedBox(height: SpiderSpace.md),
            TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: false,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit(),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              style: text.headlineMedium,
              decoration: const InputDecoration(
                labelText: 'Weight',
                suffixText: 'kg',
                filled: true,
                fillColor: SpiderColors.bg,
                border: OutlineInputBorder(
                  borderRadius: SpiderRadius.cardAll,
                  borderSide: BorderSide(color: SpiderColors.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: SpiderRadius.cardAll,
                  borderSide: BorderSide(color: SpiderColors.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: SpiderRadius.cardAll,
                  borderSide: BorderSide(
                    color: SpiderColors.accent,
                    width: 1.6,
                  ),
                ),
              ),
            ),
            const SizedBox(height: SpiderSpace.md),
            FilledButton(
              onPressed: onSubmit,
              child: const Text(SpiderCopy.logWeight),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoggedTodayCard extends StatelessWidget {
  const _LoggedTodayCard({required this.entry, required this.delta});

  final WeightLog entry;
  final double? delta;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Panel(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: SpiderColors.positive),
            const SizedBox(width: SpiderSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Logged today: ${entry.weightKg.toStringAsFixed(1)} kg',
                    style: text.titleMedium,
                  ),
                  Text(
                    delta == null
                        ? 'First reading on record.'
                        : SpiderCopy.weighInResult(delta!),
                    style: text.bodySmall?.copyWith(
                      color: SpiderColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextDueCard extends StatelessWidget {
  const _NextDueCard({required this.latest});

  final WeightLog? latest;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final days = _daysToMonday(DateTime.now());

    return Panel(
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_outlined, color: SpiderColors.textMuted),
                const SizedBox(width: SpiderSpace.md),
                Expanded(
                  child: Text(
                    days == 1
                        ? 'Next weigh-in tomorrow.'
                        : 'Next weigh-in in $days days, on Monday.',
                    style: text.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: SpiderSpace.sm),
            Text(
              latest == null
                  ? SpiderCopy.noWeightYet
                  : 'Last reading ${latest!.weightKg.toStringAsFixed(1)} kg '
                        'on ${prettyDateKey(latest!.date)}. Weekly is enough — the rest is '
                        'water.',
              style: text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  int _daysToMonday(DateTime now) {
    final delta = (DateTime.monday - now.weekday + 7) % 7;
    return delta == 0 ? 7 : delta;
  }
}

class _WeightRow extends StatelessWidget {
  const _WeightRow({required this.entry, required this.delta});

  final WeightLog entry;
  final double? delta;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final change = delta;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SpiderSpace.sm),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(prettyDateKey(entry.date), style: text.bodySmall),
          ),
          Expanded(
            child: Text(
              '${entry.weightKg.toStringAsFixed(1)} kg',
              style: text.bodyMedium,
            ),
          ),
          if (change != null)
            Text(
              '${change <= 0 ? '' : '+'}${change.toStringAsFixed(1)}',
              style: text.bodySmall?.copyWith(
                color: change <= 0
                    ? SpiderColors.positive
                    : SpiderColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

class _GoalBanner extends StatelessWidget {
  const _GoalBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SpiderSpace.md),
      decoration: BoxDecoration(
        color: SpiderColors.surfaceHigh,
        borderRadius: SpiderRadius.cardAll,
        border: Border.all(color: SpiderColors.positive),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_outlined, color: SpiderColors.positive),
          const SizedBox(width: SpiderSpace.md),
          Expanded(
            child: Text(
              SpiderCopy.goalWeightReached,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: SpiderColors.positive),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens the weigh-in screen on its own route. Weight is a weekly action,
/// so it lives behind Progress and the Home summary rather than in the bar.
void openWeighIn(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(),
        body: const SafeArea(child: WeightScreen()),
      ),
    ),
  );
}
