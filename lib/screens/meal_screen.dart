/// Meals — four slots, one tap each to open, three taps to log.
///
/// The tap budget (PRD: ≤3 taps to log anything) is spent like this:
///   1. tap the slot
///   2. tap the item(s) eaten
///   3. tap Good / Okay / Cheat — which saves and closes the sheet
///
/// So the quality rating doubles as the save button; there is no separate
/// confirm. Flagged items warn inline and never block: the PRD is explicit
/// that logging a cheat meal is the behaviour we want to encourage.
library;

import 'package:flutter/material.dart';

import '../main.dart';
import '../models/models.dart';
import '../services/repository.dart';
import '../theme/app_theme.dart';
import '../theme/spider_copy.dart';
import '../widgets/diet_score_bar.dart';
import '../widgets/web_shot.dart';

class MealScreen extends StatelessWidget {
  const MealScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = RepositoryScope.of(context);
    final text = Theme.of(context).textTheme;

    if (repo.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final logged = repo.todayMeals.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SpiderSpace.md,
        SpiderSpace.lg,
        SpiderSpace.md,
        SpiderSpace.xl,
      ),
      children: [
        Text('Meals', style: text.displaySmall),
        const SizedBox(height: SpiderSpace.xs),
        Text(
          '$logged of 4 logged today',
          style: text.bodyMedium?.copyWith(color: SpiderColors.textMuted),
        ),
        const SizedBox(height: SpiderSpace.lg),

        DietScoreBar(score: repo.todayDietScore),
        if (logged == 0) ...[
          const SizedBox(height: SpiderSpace.sm),
          Text(SpiderCopy.noMealsYet, style: text.bodySmall),
        ],
        const SizedBox(height: SpiderSpace.lg),

        for (final type in MealType.values)
          _MealSlot(
            type: type,
            log: repo.mealFor(type),
            onTap: () => _openSheet(context, repo, type),
          ),
        const Divider(),
      ],
    );
  }

  Future<void> _openSheet(
    BuildContext context,
    AppRepository repo,
    MealType type,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: SpiderColors.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _MealSheet(
        type: type,
        repo: repo,
        existing: repo.mealFor(type),
        onSave: (items, quality) {
          repo.saveMeal(type: type, items: items, quality: quality);
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }
}

/// One of the four slots: the time on the left, what was eaten on the right.
class _MealSlot extends StatelessWidget {
  const _MealSlot({required this.type, required this.log, required this.onTap});

  final MealType type;
  final MealLog? log;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final entry = log;

    return Column(
      children: [
        const Divider(),
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 72,
                  child: Text(type.window, style: text.bodySmall),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(type.label, style: text.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        entry == null
                            ? 'Not logged'
                            : entry.items.isEmpty
                            ? entry.quality.label
                            : entry.items.join(', '),
                        style: text.bodyMedium?.copyWith(
                          color: entry == null
                              ? SpiderColors.textMuted
                              : SpiderColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: SpiderSpace.sm),
                if (entry != null)
                  _QualityBadge(quality: entry.quality)
                else
                  const Icon(Icons.add, color: SpiderColors.textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact indicator of a logged meal's rating.
class _QualityBadge extends StatelessWidget {
  const _QualityBadge({required this.quality});

  final MealQuality quality;

  @override
  Widget build(BuildContext context) {
    final (Color colour, IconData icon) = switch (quality) {
      MealQuality.good => (SpiderColors.positive, Icons.check),
      MealQuality.okay => (SpiderColors.textMuted, Icons.remove),
      MealQuality.cheat => (SpiderColors.caution, Icons.bolt),
    };

    return Semantics(
      label: 'Rated ${quality.label}',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpiderSpace.sm,
          vertical: SpiderSpace.xs,
        ),
        decoration: BoxDecoration(
          borderRadius: SpiderRadius.chipAll,
          border: Border.all(color: colour.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: colour),
            const SizedBox(width: SpiderSpace.xs),
            Text(
              quality.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colour,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The logging sheet: items on top, the three rating buttons at the bottom.
class _MealSheet extends StatefulWidget {
  const _MealSheet({
    required this.type,
    required this.repo,
    required this.existing,
    required this.onSave,
  });

  final MealType type;

  /// Passed in rather than looked up: `RepositoryScope` sits below the
  /// Navigator, so a modal route's context cannot see it.
  final AppRepository repo;

  final MealLog? existing;
  final void Function(List<String> items, MealQuality quality) onSave;

  @override
  State<_MealSheet> createState() => _MealSheetState();
}

class _MealSheetState extends State<_MealSheet> {
  late final Set<String> _selected = {...?widget.existing?.items};

  /// Options from the user's plan plus the items they typed before,
  /// most-used first. Held locally so an add or remove repaints the sheet
  /// immediately; the repository's notifications don't reach a modal route.
  late List<MealOption> _options = widget.repo.optionsForMeal(widget.type);

  /// Names of the user's own items. Only these can be removed.
  late Set<String> _custom = {
    for (final o in widget.repo.customOnly(widget.type)) o.name,
  };

  final TextEditingController _query = TextEditingController();
  final FocusNode _queryFocus = FocusNode();

  @override
  void dispose() {
    _query.dispose();
    _queryFocus.dispose();
    super.dispose();
  }

  String get _q => _query.text.trim();

  /// True once a flagged item is in the selection, so a typed "samosa"
  /// warns exactly like a flagged item from the plan does.
  bool get _hasFlagged =>
      _options.any((o) => o.flagged && _selected.contains(o.name));

  bool get _exactMatch =>
      _options.any((o) => o.name.toLowerCase() == _q.toLowerCase());

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final q = _q.toLowerCase();
    final visible = q.isEmpty
        ? _options
        : _options.where((o) => o.name.toLowerCase().contains(q)).toList();
    final canAdd = q.isNotEmpty && !_exactMatch;
    final maxListHeight = MediaQuery.sizeOf(context).height * 0.38;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          SpiderSpace.md,
          0,
          SpiderSpace.md,
          SpiderSpace.md + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(widget.type.label, style: text.headlineSmall),
                const SizedBox(width: SpiderSpace.sm),
                Text(widget.type.window, style: text.bodySmall),
              ],
            ),
            const SizedBox(height: SpiderSpace.md),
            TextField(
              controller: _query,
              focusNode: _queryFocus,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => canAdd ? _add() : null,
              decoration: InputDecoration(
                hintText: 'Search, or type your own food',
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: SpiderColors.textMuted,
                ),
                suffixIcon: q.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(_query.clear),
                      ),
              ),
            ),
            const SizedBox(height: SpiderSpace.sm),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxListHeight),
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (canAdd) _AddRow(name: _q, onTap: _add),
                  for (final option in visible)
                    _ItemRow(
                      option: option,
                      selected: _selected.contains(option.name),
                      custom: _custom.contains(option.name),
                      onTap: () => setState(() {
                        if (!_selected.remove(option.name)) {
                          _selected.add(option.name);
                        }
                      }),
                      onLongPress: _custom.contains(option.name)
                          ? () => _remove(option)
                          : null,
                    ),
                  if (visible.isEmpty && !canAdd)
                    Padding(
                      padding: const EdgeInsets.all(SpiderSpace.md),
                      child: Text(
                        'Nothing here yet. Type a food above to add it.',
                        style: text.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
            if (_custom.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: SpiderSpace.xs),
                child: Text(
                  'Long-press one of your own items to remove it.',
                  style: text.bodySmall,
                ),
              ),
            if (_hasFlagged) ...[
              const SizedBox(height: SpiderSpace.sm),
              const _CheatNote(),
            ],
            const SizedBox(height: SpiderSpace.md),
            Text(
              _selected.isEmpty
                  ? 'How was it?'
                  : 'How was it? (${_selected.length} selected)',
              style: text.titleMedium,
            ),
            const SizedBox(height: SpiderSpace.sm),
            Row(
              children: [
                for (final quality in MealQuality.values) ...[
                  Expanded(
                    child: _QualityButton(
                      quality: quality,
                      selected: widget.existing?.quality == quality,
                      onTap: () => widget.onSave(_selected.toList(), quality),
                    ),
                  ),
                  if (quality != MealQuality.values.last)
                    const SizedBox(width: SpiderSpace.sm),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Adds what was typed as the user's own item and selects it.
  Future<void> _add() async {
    final name = _q;
    if (name.isEmpty) return;

    final option = await widget.repo.addCustomItem(widget.type, name);
    if (!mounted) return;

    setState(() {
      final existing = _options.indexWhere(
        (o) => o.name.toLowerCase() == option.name.toLowerCase(),
      );
      if (existing == -1) {
        _options = [option, ..._options];
        _custom = {..._custom, option.name};
        _selected.add(option.name);
      } else {
        _selected.add(_options[existing].name);
      }
      _query.clear();
    });
    _queryFocus.requestFocus();
  }

  Future<void> _remove(MealOption option) async {
    await widget.repo.removeCustomItem(widget.type, option.name);
    if (!mounted) return;

    setState(() {
      _options = [..._options]..removeWhere((o) => o.name == option.name);
      _custom = {..._custom}..remove(option.name);
      _selected.remove(option.name);
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Removed "${option.name}".'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              final restored = await widget.repo.addCustomItem(
                widget.type,
                option.name,
              );
              if (!mounted) return;
              setState(() {
                _options = [..._options, restored];
                _custom = {..._custom, restored.name};
              });
            },
          ),
        ),
      );
  }
}

/// "Add 'xyz'" row shown while the typed text matches nothing exactly.
class _AddRow extends StatelessWidget {
  const _AddRow({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: const Icon(
        Icons.add_circle_outline,
        color: SpiderColors.accent,
        size: 22,
      ),
      title: Text(
        'Add "$name"',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: SpiderColors.accent,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: const Text('Saved for next time'),
      onTap: onTap,
    );
  }
}

/// One food, as a selectable row.
class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.option,
    required this.selected,
    required this.onTap,
    this.custom = false,
    this.onLongPress,
  });

  final MealOption option;
  final bool selected;
  final VoidCallback onTap;
  final bool custom;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                size: 22,
                color: selected ? SpiderColors.accent : SpiderColors.outline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option.name,
                  style: text.bodyLarge?.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (custom) const _Tag('Yours', SpiderColors.textMuted),
              if (option.flagged) ...[
                const SizedBox(width: 6),
                const _Tag('Flagged', SpiderColors.caution),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, this.colour);

  final String label;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colour),
      ),
    );
  }
}

/// The gentle warning. Never a dialog, never a blocker.
class _CheatNote extends StatelessWidget {
  const _CheatNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SpiderSpace.md),
      decoration: BoxDecoration(
        color: SpiderColors.surfaceHigh,
        borderRadius: SpiderRadius.cardAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: SpiderColors.caution),
          const SizedBox(width: SpiderSpace.sm),
          Expanded(
            child: Text(
              SpiderCopy.cheatFoodSelected,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _QualityButton extends StatelessWidget {
  const _QualityButton({
    required this.quality,
    required this.selected,
    required this.onTap,
  });

  final MealQuality quality;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colour = switch (quality) {
      MealQuality.good => SpiderColors.positive,
      MealQuality.okay => SpiderColors.textPrimary,
      MealQuality.cheat => SpiderColors.caution,
    };

    return Semantics(
      button: true,
      selected: selected,
      label: '${quality.label}, ${quality.points} points',
      child: InkWell(
        borderRadius: SpiderRadius.cardAll,
        onTap: () {
          WebFx.shoot(context);
          onTap();
        },
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? colour.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: SpiderRadius.cardAll,
            border: Border.all(
              color: selected ? colour : SpiderColors.outline,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Text(
            quality.label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: colour),
          ),
        ),
      ),
    );
  }
}
