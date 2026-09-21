/// The user's details, goal progress, and the controls to change the plan.
library;

import 'package:flutter/material.dart';

import '../main.dart';
import '../services/repository.dart';
import '../models/models.dart' show prettyDateKey;
import '../models/user_plan.dart';
import '../theme/app_theme.dart';
import '../widgets/panel.dart';
import 'onboarding_screen.dart';
import 'plan_editor_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final text = Theme.of(context).textTheme;
    final UserProfile? p = repo.profile;
    final s = repo.state;
    final latest = repo.latestWeightKg ?? p?.currentKg;

    double? bmi;
    if (p != null && latest != null) {
      final m = p.heightCm / 100;
      bmi = latest / (m * m);
    }

    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: text.bodyMedium?.copyWith(color: SpiderColors.textMuted),
          ),
          const SizedBox(width: SpiderSpace.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: text.bodyLarge,
            ),
          ),
        ],
      ),
    );

    Widget section(String title, List<Widget> rows) => Padding(
      padding: const EdgeInsets.only(bottom: SpiderSpace.md),
      child: Panel(
        child: Padding(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: text.titleMedium),
              const SizedBox(height: SpiderSpace.sm),
              ...rows,
            ],
          ),
        ),
      ),
    );

    final trainingDays = repo.plan.week.where((d) => d.isTraining).length;
    final lost = latest == null ? null : s.startWeight - latest;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(SpiderSpace.md),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: SpiderColors.accent,
                child: Text(
                  (p?.name.isNotEmpty ?? false)
                      ? p!.name.characters.first.toUpperCase()
                      : '?',
                  style: text.headlineMedium,
                ),
              ),
              const SizedBox(width: SpiderSpace.md),
              Expanded(child: Text(p?.name ?? 'You', style: text.displaySmall)),
            ],
          ),
          const SizedBox(height: SpiderSpace.lg),
          if (p != null)
            section('About you', [
              row('Age', '${p.age}'),
              row('Height', '${p.heightCm.toStringAsFixed(0)} cm'),
              if (bmi != null) row('BMI', bmi.toStringAsFixed(1)),
              row('Workout setup', p.workoutType),
              row('Training days', '${p.daysPerWeek} per week'),
              if (p.diet.trim().isNotEmpty) row('Diet', p.diet.trim()),
            ]),
          section('Goal', [
            row('Started at', '${s.startWeight.toStringAsFixed(1)} kg'),
            if (latest != null) row('Now', '${latest.toStringAsFixed(1)} kg'),
            row('Goal', '${s.goalWeight.toStringAsFixed(1)} kg'),
            if (lost != null)
              row(
                lost >= 0 ? 'Lost so far' : 'Gained so far',
                '${lost.abs().toStringAsFixed(1)} kg',
              ),
            row('Goal date', prettyDateKey(s.goalDate)),
            row('Days left', '${repo.daysToGoal.clamp(0, 100000)}'),
          ]),
          section('Progress', [
            row('Current streak', '${s.currentStreak} days'),
            row(
              'Workouts completed',
              '${repo.allWorkouts.where((w) => w.completed).length}',
            ),
            row('Active days in plan', '$trainingDays per week'),
          ]),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Sound effects'),
            subtitle: const Text('Web-shot sounds and level-up chimes'),
            value: repo.soundOn,
            onChanged: repo.setSoundOn,
            activeThumbColor: SpiderColors.accent,
          ),
          const SizedBox(height: SpiderSpace.lg),
          OutlinedButton.icon(
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit workout plan'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PlanEditorScreen(
                  initial: repo.plan.week,
                  onSave: (week) async {
                    await repo.updateWorkoutPlan(week);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: SpiderSpace.sm),
          FilledButton.icon(
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Edit details & get a new plan'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OnboardingScreen(initial: p, editing: true),
              ),
            ),
          ),
          const SizedBox(height: SpiderSpace.xs),
          Text(
            'Your logs and streak are kept when you swap the plan.',
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: SpiderColors.textMuted),
          ),
          const SizedBox(height: SpiderSpace.lg),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: SpiderColors.danger),
            onPressed: () => _confirmReset(context, repo),
            child: const Text('Delete all my data and start over'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, AppRepository repo) async {
    final nav = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete everything?'),
        content: const Text(
          'This erases your profile, plan and every log on this phone. '
          'It cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await repo.resetEverything();
    nav.popUntil((r) => r.isFirst);
  }
}
