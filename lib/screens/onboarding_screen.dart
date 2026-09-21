/// Sign-up: tell us about yourself, copy the generated prompt into any
/// LLM, paste its answer back. Everything stays on the device.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../models/models.dart' show MealType;
import '../models/user_plan.dart';
import 'plan_editor_screen.dart';
import '../services/plan_prompt.dart';
import '../theme/app_theme.dart';
import '../theme/spider_copy.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.initial, this.editing = false});

  /// True when re-planning from the profile page: finishing keeps all logs.
  final bool editing;

  /// Prefills the form when known.
  final UserProfile? initial;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _current = TextEditingController();
  final _goal = TextEditingController();
  final _weeks = TextEditingController(text: '12');
  final _custom = TextEditingController();
  final _diet = TextEditingController();
  final _paste = TextEditingController();

  static const _setups = [
    'Bodyweight at home',
    'Gym',
    'Dumbbells at home',
    'Running / outdoors',
    'Yoga / mobility',
    'Other',
  ];
  String _setup = _setups.first;
  int _days = 5;

  UserProfile? _profile;
  String? _error;
  bool _busy = false;

  bool get _editing => widget.editing;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    if (i == null) return;
    _name.text = i.name;
    _age.text = '${i.age}';
    _height.text = i.heightCm.toStringAsFixed(0);
    _current.text = i.currentKg.toString();
    _goal.text = i.goalKg.toString();
    _weeks.text = '${i.weeks}';
    if (_setups.contains(i.workoutType)) {
      _setup = i.workoutType;
    } else {
      _setup = 'Other';
      _custom.text = i.workoutType;
    }
    _days = i.daysPerWeek.clamp(2, 6);
    _diet.text = i.diet;
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _age,
      _height,
      _current,
      _goal,
      _weeks,
      _custom,
      _diet,
      _paste,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _num(String? v, {required double min, required double max}) {
    final n = double.tryParse((v ?? '').trim());
    if (n == null) return 'Enter a number';
    if (n < min || n > max) return 'Between ${min.toInt()} and ${max.toInt()}';
    return null;
  }

  /// The profile from the form, or null (and the errors shown) if invalid.
  UserProfile? _profileFromForm() {
    if (!_form.currentState!.validate()) return null;
    FocusScope.of(context).unfocus();
    return UserProfile(
      name: _name.text.trim(),
      age: int.parse(_age.text.trim()),
      heightCm: double.parse(_height.text.trim()),
      currentKg: double.parse(_current.text.trim()),
      goalKg: double.parse(_goal.text.trim()),
      weeks: int.parse(_weeks.text.trim()),
      workoutType: _setup == 'Other' && _custom.text.trim().isNotEmpty
          ? _custom.text.trim()
          : _setup,
      daysPerWeek: _days,
      diet: _diet.text,
    );
  }

  void _generate() {
    final p = _profileFromForm();
    if (p == null) return;
    setState(() {
      _error = null;
      _profile = p;
    });
  }

  /// Skips the AI: the user builds the workout week by hand. Meals start
  /// empty, since typed foods are remembered as they're logged.
  void _buildOwn() {
    final p = _profileFromForm();
    if (p == null) return;
    final repo = RepositoryScope.of(context);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlanEditorScreen(
          initial: _editing ? repo.plan.week : emptyWeek(),
          saveLabel: _editing ? 'Replace my plan' : 'Start tracking',
          onSave: (week) async {
            if (_editing) {
              await repo.replan(p, repo.plan.withWeek(week));
            } else {
              await repo.completeOnboarding(
                p,
                UserPlan(
                  week: week,
                  meals: {for (final t in MealType.values) t: const []},
                ),
              );
            }
            if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
          },
        ),
      ),
    );
  }

  Future<void> _finish() async {
    final repo = RepositoryScope.of(context);
    try {
      final plan = parsePlanReply(_paste.text);
      setState(() => _busy = true);
      if (_editing) {
        await repo.replan(_profile!, plan);
        if (mounted) Navigator.of(context).pop();
      } else {
        await repo.completeOnboarding(_profile!, plan);
      }
    } on FormatException catch (e) {
      setState(() {
        _busy = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final profile = _profile;

    return Scaffold(
      appBar: _editing ? AppBar() : null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(SpiderSpace.md),
          children: [
            Text(
              _editing ? SpiderCopy.editTitle : SpiderCopy.onboardTitle,
              style: text.displaySmall,
            ),
            const SizedBox(height: SpiderSpace.xs),
            Text(
              SpiderCopy.onboardSubtitle,
              style: text.bodyMedium?.copyWith(color: SpiderColors.textMuted),
            ),
            const SizedBox(height: SpiderSpace.lg),
            Form(
              key: _form,
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Name'),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        (v ?? '').trim().isEmpty ? 'Enter your name' : null,
                  ),
                  const SizedBox(height: SpiderSpace.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _age,
                          decoration: const InputDecoration(labelText: 'Age'),
                          keyboardType: TextInputType.number,
                          validator: (v) => _num(v, min: 10, max: 100),
                        ),
                      ),
                      const SizedBox(width: SpiderSpace.md),
                      Expanded(
                        child: TextFormField(
                          controller: _height,
                          decoration: const InputDecoration(
                            labelText: 'Height (cm)',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) => _num(v, min: 100, max: 250),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SpiderSpace.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _current,
                          decoration: const InputDecoration(
                            labelText: 'Current weight (kg)',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (v) => _num(v, min: 25, max: 300),
                        ),
                      ),
                      const SizedBox(width: SpiderSpace.md),
                      Expanded(
                        child: TextFormField(
                          controller: _goal,
                          decoration: const InputDecoration(
                            labelText: 'Goal weight (kg)',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (v) => _num(v, min: 25, max: 300),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SpiderSpace.md),
                  TextFormField(
                    controller: _weeks,
                    decoration: const InputDecoration(
                      labelText: 'Weeks to reach goal',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => _num(v, min: 2, max: 104),
                  ),
                  const SizedBox(height: SpiderSpace.md),
                  DropdownButtonFormField<String>(
                    initialValue: _setup,
                    decoration: const InputDecoration(
                      labelText: 'Type of workout',
                    ),
                    items: [
                      for (final s in _setups)
                        DropdownMenuItem(value: s, child: Text(s)),
                    ],
                    onChanged: (v) => setState(() => _setup = v ?? _setup),
                  ),
                  if (_setup == 'Other') ...[
                    const SizedBox(height: SpiderSpace.md),
                    TextFormField(
                      controller: _custom,
                      decoration: const InputDecoration(
                        labelText: 'Describe what you can do',
                      ),
                    ),
                  ],
                  const SizedBox(height: SpiderSpace.md),
                  DropdownButtonFormField<int>(
                    initialValue: _days,
                    decoration: const InputDecoration(
                      labelText: 'Training days / week',
                    ),
                    items: [
                      for (var d = 2; d <= 6; d++)
                        DropdownMenuItem(value: d, child: Text('$d days')),
                    ],
                    onChanged: (v) => setState(() => _days = v ?? _days),
                  ),
                  const SizedBox(height: SpiderSpace.md),
                  TextFormField(
                    controller: _diet,
                    decoration: const InputDecoration(
                      labelText: 'Diet (optional)',
                      hintText: 'e.g. vegetarian, hostel mess, no dairy',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: SpiderSpace.lg),
            FilledButton(
              onPressed: _generate,
              child: Text(
                profile == null
                    ? SpiderCopy.onboardGenerate
                    : SpiderCopy.onboardRegenerate,
              ),
            ),
            const SizedBox(height: SpiderSpace.sm),
            OutlinedButton(
              onPressed: _buildOwn,
              child: const Text('Build my own workout plan'),
            ),
            if (profile != null) ...[
              const SizedBox(height: SpiderSpace.xl),
              Text('1. Copy this prompt', style: text.titleLarge),
              const SizedBox(height: SpiderSpace.xs),
              Text(
                SpiderCopy.onboardCopyHelp,
                style: text.bodySmall?.copyWith(color: SpiderColors.textMuted),
              ),
              const SizedBox(height: SpiderSpace.sm),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(SpiderSpace.md),
                  child: SelectableText(
                    buildPlanPrompt(profile, DateTime.now()),
                    maxLines: 8,
                    style: text.bodySmall,
                  ),
                ),
              ),
              const SizedBox(height: SpiderSpace.sm),
              OutlinedButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('Copy prompt'),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await Clipboard.setData(
                    ClipboardData(
                      text: buildPlanPrompt(profile, DateTime.now()),
                    ),
                  );
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Prompt copied. Paste it into any AI.'),
                    ),
                  );
                },
              ),
              const SizedBox(height: SpiderSpace.xl),
              Text('2. Paste the AI’s answer', style: text.titleLarge),
              const SizedBox(height: SpiderSpace.sm),
              TextField(
                controller: _paste,
                minLines: 5,
                maxLines: 10,
                decoration: InputDecoration(
                  hintText: '{ "week": [ … ], "meals": { … } }',
                  errorText: _error,
                  errorMaxLines: 4,
                ),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
              const SizedBox(height: SpiderSpace.sm),
              OutlinedButton.icon(
                icon: const Icon(Icons.paste),
                label: const Text('Paste from clipboard'),
                onPressed: () async {
                  final d = await Clipboard.getData(Clipboard.kTextPlain);
                  if (d?.text != null) setState(() => _paste.text = d!.text!);
                },
              ),
              const SizedBox(height: SpiderSpace.md),
              FilledButton(
                onPressed: _busy ? null : _finish,
                child: Text(
                  _busy
                      ? 'Setting up…'
                      : (_editing
                            ? SpiderCopy.editFinish
                            : SpiderCopy.onboardFinish),
                ),
              ),
            ],
            const SizedBox(height: SpiderSpace.xl),
            Text(
              SpiderCopy.onboardPrivacy,
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: SpiderColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
