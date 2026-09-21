/// Build or edit the workout week by hand: no AI needed.
///
/// Two levels: the week (seven days, each a row) and a day (a title and a
/// list of exercises). A day with no exercises is a rest day.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// A seven-day empty week, every day a rest day.
List<WorkoutDay> emptyWeek() => [
  for (final d in _weekdays)
    WorkoutDay(
      title: d,
      short: d.substring(0, 3),
      duration: '—',
      exercises: const [],
    ),
];

class PlanEditorScreen extends StatefulWidget {
  const PlanEditorScreen({
    super.key,
    required this.initial,
    required this.onSave,
    this.saveLabel = 'Save plan',
  });

  /// Seven days, Monday first.
  final List<WorkoutDay> initial;

  /// Called with the finished week. The caller closes the editor.
  final Future<void> Function(List<WorkoutDay> week) onSave;
  final String saveLabel;

  @override
  State<PlanEditorScreen> createState() => _PlanEditorScreenState();
}

class _PlanEditorScreenState extends State<PlanEditorScreen> {
  late final List<WorkoutDay> _week = [...widget.initial];
  bool _saving = false;

  int get _trainingDays => _week.where((d) => d.isTraining).length;

  Future<void> _edit(int i) async {
    final updated = await Navigator.of(context).push<WorkoutDay>(
      MaterialPageRoute(
        builder: (_) => _DayEditor(weekday: _weekdays[i], day: _week[i]),
      ),
    );
    if (updated != null) setState(() => _week[i] = updated);
  }

  Future<void> _save() async {
    if (_trainingDays == 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Add exercises to at least one day.')),
        );
      return;
    }
    setState(() => _saving = true);
    await widget.onSave(_week);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Workout plan')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                SpiderSpace.md,
                SpiderSpace.sm,
                SpiderSpace.md,
                SpiderSpace.md,
              ),
              children: [
                Text(
                  'Set what you do each day. A day with no exercises is a rest day.',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: SpiderSpace.md),
                for (var i = 0; i < 7; i++) ...[
                  const Divider(),
                  InkWell(
                    onTap: () => _edit(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 96,
                            child: Text(_weekdays[i], style: text.titleMedium),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _week[i].isRest ? 'Rest day' : _week[i].title,
                                  style: text.bodyLarge?.copyWith(
                                    color: _week[i].isRest
                                        ? SpiderColors.textMuted
                                        : SpiderColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (!_week[i].isRest)
                                  Text(
                                    '${_week[i].exercises.length} exercises',
                                    style: text.bodySmall,
                                  ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: SpiderColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const Divider(),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: SpiderColors.bg,
              border: Border(top: BorderSide(color: SpiderColors.outline)),
            ),
            padding: const EdgeInsets.all(SpiderSpace.md),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving…' : widget.saveLabel),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Editable copy of one exercise, with the controllers its fields need.
class _Draft {
  _Draft.from(Exercise? e)
    : name = TextEditingController(text: e?.name ?? ''),
      sets = TextEditingController(text: '${e?.sets ?? 3}'),
      amount = TextEditingController(text: '${e?.reps ?? e?.seconds ?? 10}'),
      timed = e?.seconds != null,
      perSide = e?.perSide ?? false;

  final TextEditingController name;
  final TextEditingController sets;
  final TextEditingController amount;
  bool timed;
  bool perSide;

  void dispose() {
    name.dispose();
    sets.dispose();
    amount.dispose();
  }

  /// Null when the row is blank or unusable, so it is simply dropped.
  Exercise? toExercise() {
    final n = name.text.trim();
    final s = int.tryParse(sets.text.trim());
    final a = int.tryParse(amount.text.trim());
    if (n.isEmpty || s == null || a == null || s < 1 || a < 1) return null;
    return Exercise(
      name: n,
      sets: s.clamp(1, 20),
      reps: timed ? null : a,
      seconds: timed ? a : null,
      perSide: perSide,
    );
  }
}

class _DayEditor extends StatefulWidget {
  const _DayEditor({required this.weekday, required this.day});

  final String weekday;
  final WorkoutDay day;

  @override
  State<_DayEditor> createState() => _DayEditorState();
}

class _DayEditorState extends State<_DayEditor> {
  late final TextEditingController _title = TextEditingController(
    text: widget.day.isRest ? '' : widget.day.title,
  );
  late final TextEditingController _duration = TextEditingController(
    text: widget.day.duration == '—' ? '' : widget.day.duration,
  );
  late final List<_Draft> _drafts = [
    for (final e in widget.day.exercises) _Draft.from(e),
  ];

  @override
  void dispose() {
    _title.dispose();
    _duration.dispose();
    for (final d in _drafts) {
      d.dispose();
    }
    super.dispose();
  }

  void _done() {
    final exercises = [
      for (final d in _drafts)
        if (d.toExercise() != null) d.toExercise()!,
    ];
    if (exercises.isEmpty) {
      Navigator.of(context).pop(
        WorkoutDay(
          title: widget.weekday,
          short: widget.weekday.substring(0, 3),
          duration: '—',
          exercises: const [],
        ),
      );
      return;
    }
    final title = _title.text.trim().isEmpty
        ? widget.weekday
        : _title.text.trim();
    final first = title.split(RegExp(r'[\s\-–,]+')).first;
    Navigator.of(context).pop(
      WorkoutDay(
        title: title,
        short: first.length > 8 ? first.substring(0, 8) : first,
        duration: _duration.text.trim().isEmpty ? '—' : _duration.text.trim(),
        exercises: exercises,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.weekday)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(SpiderSpace.md),
              children: [
                TextField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Day name',
                    hintText: 'e.g. Upper body',
                  ),
                ),
                const SizedBox(height: SpiderSpace.md),
                TextField(
                  controller: _duration,
                  decoration: const InputDecoration(
                    labelText: 'How long (optional)',
                    hintText: 'e.g. 40 min',
                  ),
                ),
                const SizedBox(height: SpiderSpace.lg),
                Text('Exercises', style: text.titleLarge),
                const SizedBox(height: SpiderSpace.sm),
                for (var i = 0; i < _drafts.length; i++)
                  _DraftRow(
                    key: ObjectKey(_drafts[i]),
                    draft: _drafts[i],
                    onChanged: () => setState(() {}),
                    onRemove: () => setState(() {
                      _drafts.removeAt(i).dispose();
                    }),
                  ),
                const Divider(),
                const SizedBox(height: SpiderSpace.sm),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _drafts.add(_Draft.from(null))),
                      icon: const Icon(Icons.add),
                      label: const Text('Add exercise'),
                    ),
                    const Spacer(),
                    if (_drafts.isNotEmpty)
                      TextButton(
                        onPressed: () => setState(() {
                          for (final d in _drafts) {
                            d.dispose();
                          }
                          _drafts.clear();
                        }),
                        child: const Text('Make rest day'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: SpiderColors.bg,
              border: Border(top: BorderSide(color: SpiderColors.outline)),
            ),
            padding: const EdgeInsets.all(SpiderSpace.md),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _done,
                  child: Text(_drafts.isEmpty ? 'Save as rest day' : 'Done'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftRow extends StatelessWidget {
  const _DraftRow({
    super.key,
    required this.draft,
    required this.onChanged,
    required this.onRemove,
  });

  final _Draft draft;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final digits = [FilteringTextInputFormatter.digitsOnly];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: SpiderSpace.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: draft.name,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Exercise'),
              ),
            ),
            IconButton(
              tooltip: 'Remove exercise',
              onPressed: onRemove,
              icon: const Icon(
                Icons.delete_outline,
                color: SpiderColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: SpiderSpace.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: draft.sets,
                keyboardType: TextInputType.number,
                inputFormatters: digits,
                decoration: const InputDecoration(labelText: 'Sets'),
              ),
            ),
            const SizedBox(width: SpiderSpace.sm),
            Expanded(
              child: TextField(
                controller: draft.amount,
                keyboardType: TextInputType.number,
                inputFormatters: digits,
                decoration: InputDecoration(
                  labelText: draft.timed ? 'Seconds' : 'Reps',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: SpiderSpace.sm),
        Row(
          children: [
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: false, label: Text('Reps')),
                ButtonSegment(value: true, label: Text('Timed')),
              ],
              selected: {draft.timed},
              onSelectionChanged: (v) {
                draft.timed = v.first;
                onChanged();
              },
            ),
            const Spacer(),
            const Text('Each side'),
            Switch(
              value: draft.perSide,
              activeThumbColor: SpiderColors.accent,
              onChanged: (v) {
                draft.perSide = v;
                onChanged();
              },
            ),
          ],
        ),
        const SizedBox(height: SpiderSpace.sm),
      ],
    );
  }
}
