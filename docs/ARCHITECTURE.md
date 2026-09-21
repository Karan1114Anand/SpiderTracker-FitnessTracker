# Architecture

Flutter app, Android target, fully offline. One `ChangeNotifier` over SQLite;
no state-management package.

```
lib/
  main.dart                 entry, five-tab shell, sound/animation on achievements
  models/
    models.dart             data contract: rows, enums, dateKey()
    user_plan.dart          UserProfile, UserPlan (week, meals, run stages) + JSON validation
    game.dart               daily points and levels (pure functions)
    badges.dart             badge definitions and progress (pure functions)
  services/
    database.dart           sqflite schema (v5), migrations, queries
    repository.dart         the single state layer screens read and mutate through
    plan_prompt.dart        builds the LLM prompt, parses and validates the reply
    sfx.dart                sound effects over a platform channel
  screens/                  home, workout, meals, run, progress, weight, rank,
                            profile, onboarding, plan_editor
  widgets/                  web_radar, web_ring, web_shot, panel, figure, diet_score_bar
  theme/                    design tokens and Material theme
android/.../MainActivity.kt SoundPool channel for effects
```

## Rules the code follows

- Screens never touch `database.dart`; they use `AppRepository`.
- Points, levels and badges are **derived** from the logs and never stored, so
  editing a log corrects them automatically.
- No preset workouts or dishes ship in the app. Everything comes from the plan
  the user pasted or built.
- Every schema change bumps the database version and adds an upgrade branch.

## Plan JSON

The AI reply is validated by `UserPlan.fromJson`: seven days (Monday first),
each with `title`, `duration` and `exercises` (`name`, `sets`, `reps` or
`seconds`, optional `per_side`); four meal lists (`breakfast`, `lunch`, `snack`,
`dinner`) of `{name, flagged}`; and an optional `run` block. The prompt in
`plan_prompt.dart` documents the exact shape.

## Tests

`flutter test` covers pure logic (points, levels, badges, plan parsing), the
plan editor, and a loading-state smoke test per screen.
