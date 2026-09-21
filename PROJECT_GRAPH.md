# Spider-Tracker — Project Graph & Handoff

**Owner:** Karan Anand · **Written:** 2026-09-22 · **Status:** feature-complete backend + all 6 screens; **no APK yet**

A local-only Flutter Android app to log workouts, mess meals, weekly weight and evening runs.
Goal: 95 kg → 82.5 kg by 2026-12-01. Spider-Man themed. No backend, no login, no network.

> **Read this file first.** It is the complete state of the project. The original PRD is
> reproduced in `docs/PRD.md` — it is the contract; when in doubt, it wins.

---

## 0. Orientation — where things are

```
/home/klaus/Projects/Spider-Tracker/     ← canonical location (this dir)
/home/klaus/.openclaw/workspace/spider-tracker/   ← original; identical copy, now stale.
                                                     Delete once you trust this one.
```

Flutter SDK is **not on PATH**. Every command below needs:

```bash
export PATH="$PATH:/home/klaus/devtools/flutter/bin"
cd /home/klaus/Projects/Spider-Tracker
```

Android SDK lives at `/home/klaus/devtools/android-sdk` (platform-tools, android-35,
build-tools 35.0.0 installed; Flutter already configured to point at it).
`android/local.properties` holds both paths — it is machine-local, do not commit it.

**Verified working as of 2026-09-22:**

| Check | Result |
|---|---|
| `flutter analyze` | No issues found (whole tree) |
| `flutter test` | 23/23 passing |
| `flutter build apk` | **never run** |

---

## 1. Dependency graph — how the code fits together

```
                          main.dart
              (entry · RootShell · RepositoryScope · TabSwitcher)
                               │
                 ┌─────────────┴──────────────┐
                 ▼                            ▼
         theme/app_theme.dart          services/repository.dart
         theme/spider_copy.dart          (ChangeNotifier · THE state layer)
                 │                            │
                 │                            ▼
                 │                    services/database.dart
                 │                    (sqflite · schema v2 · streak calc)
                 │                            │
                 ▼                            ▼
            widgets/                     models/models.dart
   spider_mark · stat_card                (data contract — do not
   streak_web · web_grid_background        redefine these types)
   web_strength_meter                          ▲
                 ▲                              │
                 │                      data/workout_plan.dart  (hard-coded 7-day plan
                 │                      data/mess_menu.dart      + RunTarget ladder)
                 │                             ▲
                 └──────────┬──────────────────┘
                            ▼
                        screens/
   home · workout · meal · run · weight · progress
```

**The one rule:** screens never touch `database.dart`. They read fields off
`AppRepository` and call its mutators. One write → one `notifyListeners()` → one rebuild.

### File inventory (5,317 lines of Dart)

| File | Lines | What it owns |
|---|---|---|
| `lib/main.dart` | 191 | App entry, 5-tab nav shell, run-tab lock |
| `lib/models/models.dart` | 267 | **Data contract.** `dateKey()`, all enums, all row types, `AppState.initial` |
| `lib/services/database.dart` | 424 | sqflite schema v2, migrations, `computeStreak`, `refreshDerivedState` |
| `lib/services/repository.dart` | 186 | ChangeNotifier state layer; today's slice held in memory |
| `lib/data/workout_plan.dart` | 186 | Mon–Sun hard-coded plan + `RunTarget` Oct/Nov ladder |
| `lib/data/mess_menu.dart` | 107 | Preset meal options per `MealType`, with `flagged` bools |
| `lib/theme/app_theme.dart` | 234 | Navy/crimson/gold palette, Bebas Neue + Inter via google_fonts |
| `lib/theme/spider_copy.dart` | 113 | Every themed UX string in one place |
| `lib/screens/home_screen.dart` | 277 | Dashboard: today's workout, meals, streak, weight mini-chart |
| `lib/screens/workout_screen.dart` | 253 | Per-set checklist, completion trigger |
| `lib/screens/meal_screen.dart` | 707 | 4 slots, preset + custom picker, flag warning, quality rating |
| `lib/screens/run_screen.dart` | 461 | Distance/duration entry, locked until 1 Oct |
| `lib/screens/weight_screen.dart` | 404 | Monday-only weigh-in |
| `lib/screens/progress_screen.dart` | 629 | Weight trend (fl_chart), workout heatmap, diet history |
| `lib/widgets/*.dart` | 718 | streak web, strength meter, stat cards, grid background |
| `test/logic_test.dart` | 160 | 23 pure-logic tests — no widget tests exist |

---

## 2. Data model (schema v2)

Five tables, all keyed on a `YYYY-MM-DD` string. `dateKey()` in `models.dart` is the
single place `DateTime` ever becomes a key.

| Table | Key | Notes |
|---|---|---|
| `workout_log` | `date` | `sets_done` is JSON `[{exercise, sets_completed}]`; `completed` bool |
| `meal_log` | `(date, meal_type)` | `items` JSON array; `quality` good/okay/cheat |
| `weight_log` | `date` | Monday dates only — enforced at service layer, not by the schema |
| `run_log` | `date` | distance_km float, duration_min int |
| `app_state` | single row `id=1` | start 95.0, goal 82.5, goal_date, current_streak, run_unlocked |
| `custom_item` | — | **v2 addition.** User-typed meal items, per type, with use counter |

**Migration discipline:** `_version = 2` in `database.dart`. Bump it *and* add an
`_upgrade` branch for any schema change, or existing installs crash on the missing column.

**Derived, never stored by hand:** `current_streak` and `run_unlocked` are recomputed by
`refreshDerivedState()` on launch and after every workout write.

**Streak semantics (deliberate, don't "fix" it):** counts back from *yesterday* when today
isn't logged yet, so the streak doesn't read zero at 9am. Rest days count — the plan
prescribes them, so honouring the plan is what's rewarded.

---

## 3. What is DONE

- [x] Full data model + sqflite schema, v1→v2 migration path
- [x] Repository state layer; no screen touches the DB directly
- [x] Hard-coded 7-day workout plan (Mon push → Sun full rest)
- [x] Mess menu, expanded to ~48 items (breakfast 16 / lunch-dinner 18 / snack 14)
- [x] Custom meal entry — typed items remembered per meal type, sorted by use count,
      keyword auto-flagging so a typed "samosa" still warns
- [x] Diet score: good=2, okay=1, cheat=0, max 8/day
- [x] Streak computation with the rest-day rule above
- [x] Run tab gated on 1 Oct 2026 — visible but locked, with a snackbar
- [x] All six screens built and compiling
- [x] Spider-Man theme: palette, Bebas Neue + Inter, web-grid background, growing streak web
- [x] 23 logic tests passing; `flutter analyze` clean
- [x] Android SDK toolchain installed and Flutter configured
- [x] Web preview path (IndexedDB swap in `main.dart`, `kIsWeb` only — Android untouched)

---

## 4. What needs DOING

Ordered. Blockers first.

### 🔴 B1 — Nav bar shows 5 destinations for 6 pages *(bug, ~10 min)*

`lib/main.dart:126` builds a 6-entry `pages` list (Home, Workout, Meal, Run, Weight,
Progress) but `NavigationBar` at `:159` declares only **5** destinations, ending at Weight.

**Consequence: the Progress screen is unreachable.** 629 lines of weight trend, heatmap
and diet history that no user can navigate to. The PRD (§08) specifies a bottom nav with
5 icons *and* lists Progress as a screen — so the PRD is internally inconsistent here.

Pick one, then do it:
- Add a 6th destination (simplest; breaks the PRD's "5 icons" line), **or**
- Drop Progress from `pages` and reach it from a Home dashboard tap via the existing
  `TabSwitcher` (honours the PRD; needs an entry point on Home).

Recommend the 6th destination. Ask Karan — it's a UX call, not a code one.

### 🔴 B2 — Diet score history only ever shows today *(bug, ~30 min)*

`lib/screens/progress_screen.dart:102` passes `{repo.today: repo.todayDietScore}` — a
single-entry map. `_DietHistory` is built to render a series and sorts its keys, so the
widget is fine; the data isn't there.

`database.dart:268` already has `dietScoreOn(String date)`. Needed:
1. A `dietScoresBetween(start, end)` (or `recentDietScores(days)`) in `database.dart`
2. Expose it on `AppRepository`, loaded in `load()` alongside the rest of today's slice
3. Pass the real map at `progress_screen.dart:102`

PRD §11 targets "≥6/8 daily diet score on average" — that metric is unmeasurable until
this lands.

### 🟠 B3 — Ship the APK *(the actual remaining deliverable)*

Never built. Gradle's first run takes several minutes; budget for it.

```bash
export PATH="$PATH:/home/klaus/devtools/flutter/bin"
cd /home/klaus/Projects/Spider-Tracker
flutter build apk --release
```

Before building, fix the three defaults:

| Thing | Currently | Should be |
|---|---|---|
| `applicationId` (`android/app/build.gradle.kts:24`) | `com.example.spider_tracker` | e.g. `dev.karan.spidertracker` |
| `android:label` (`AndroidManifest.xml:3`) | `spider_tracker` | `Spider-Tracker` |
| Launcher icon (`res/mipmap-*/ic_launcher.png`) | default Flutter | spider mark |

`com.example.*` is fine for sideloading but is a package namespace you don't own — change
it before it ends up on the phone and becomes annoying to migrate.

Then: `adb install -r build/app/outputs/flutter-apk/app-release.apk`.

### 🟡 B4 — Verify on a real device

Everything so far is verified via web preview, which runs on IndexedDB, **not** SQLite.
The Android sqflite path has never executed. Specifically untested on device:

- Real SQLite open/migrate (the v1→v2 `_upgrade` branch has never run anywhere)
- `google_fonts` fetching Bebas Neue + Inter at runtime — **needs network on first launch**.
  An offline-first app that renders wrong until it sees the internet once is a defect
  worth knowing about. Consider bundling the two fonts as assets instead.
- System UI overlay colours, safe areas, back-button behaviour

### 🟡 B5 — No widget tests

All 23 tests are pure logic. Not one screen is tested. `_DietHistory` (B2) would have been
caught by a single widget test. At minimum: a smoke test per screen that pumps it with a
seeded repository.

### 🟢 B6 — Open design questions for Karan

1. **Goal date conflict.** PRD body says "Dec 2026", metrics table says "by Dec 1", data
   model says `2026-11-30`. Code uses **2026-12-01** (`models.dart:252`) to match the
   stated metric. Confirm.
2. **Food photo diary.** Karan asked about camera → calories. That was declined, correctly:
   PRD §10 puts calorie counting in V2 ("too complex for mess food"), and a vision API
   would break the "no data sent anywhere" promise. The counter-offer — a photo attached
   to a meal log as a *local record*, no API, no upload — was put to Karan and **never
   answered**. Still open.
3. **HIIT circuits are flattened.** Thursday is "3 circuits × 5 stations, 20s rest". The
   `Exercise` model has no rest field, so it's stored as 5 exercises × 3 sets × 40s. Total
   work is right; the UI shows five sequential exercises, not three rounds. Fine, or model it?
4. **December has no run target.** The `RunTarget` ladder stops at November, and December
   currently inherits November's final target rather than returning null. Goal date is in
   December.
5. **Saturday walk** is stored as `1 set × 2700s` — the top of the "30–45 min" range,
   because one `Exercise` can't hold a range.

### 🟢 B7 — Explicitly out of scope (PRD §10)

Calorie counting, photo log, social/sharing, Play Store, cloud sync, iOS, custom workout
editor. **CSV export is V2** — don't build it now, but the local-only design assumes it
eventually exists as the backup story.

---

## 5. Suggested order of work

```
B1 (nav) ──┐
           ├──► B4 (device verify) ──► B3 (APK, after ids/icon) ──► ship
B2 (diet) ─┘
                B5 (widget tests) — anytime, ideally before B3
                B6 — ask Karan; blocks nothing except #1 and #2
```

Both B1 and B2 are small, isolated and independently testable. Do them, run
`flutter analyze && flutter test`, then go for the APK.

---

## 6. Conventions to keep

- **`models.dart` is a contract.** Add to it; don't redefine its types elsewhere.
- **Screens don't touch the database.** Go through `AppRepository`.
- **All user-facing strings live in `spider_copy.dart`.** Don't inline Spider-Man copy.
- **Bump `_version` + add an `_upgrade` branch** for every schema change.
- **Flags never block.** A flagged food shows "Peter Parker wouldn't" and logs anyway.
  Awareness, not enforcement — this is load-bearing to the PRD's design.
- **No calorie math.** Anywhere. Ever. (PRD §05)
- The web preview path is `kIsWeb`-guarded in `main.dart` and is **preview only**.
  `web/sqlite3.wasm` and `web/sqflite_sw.js` are required assets for it — they don't
  install automatically, and without them the app hangs forever on a silent splash.

---

## 7. Lesson recorded

The web preview was once declared working on the strength of an HTTP 200 from the server.
The app was in fact hanging on `_repo.load()`, awaiting a database that could never open,
because two `sqflite_common_ffi_web` binary assets were missing.

**Serving a page is not running an app.** Before telling Karan something works, load it.
This applies directly to B3: `flutter build apk` succeeding is not the same as the app
launching on the phone.

---

## 8. Update 2026-09-22 (later)

Done: B1 (6th Progress tab), B2 (`allDietScores` → `repo.dietScores`), B3 (applicationId
`dev.karan.spidertracker`, label, generated spider launcher icon, APK built), Inter + Bebas Neue
bundled in `assets/google_fonts/`, B5 smoke tests (29 tests total, loading-state only).

Build notes: needs **JDK 17** (`~/devtools/jdk17`, set via `flutter config --jdk-dir`);
JDK 25 breaks Gradle and the JDK 21 install has no javac. Gradle wrapper switched to `-bin`.
Not done: B4 on-device run (no device attached), B6 questions still need Karan.

---

## 9. Status at v1.7.0 (supersedes sections 3, 4 and 8)

The app is now a **general, fully local tracker**; nothing about one user is hard-coded.

- **Sign-up:** name, age, height, weights, weeks to goal, workout type, days per week, diet.
  Then either copy a generated prompt into any LLM and paste back its JSON (`plan_prompt.dart`,
  `user_plan.dart` validates it), or build the workout week by hand (`plan_editor_screen.dart`).
- **No preset content:** meals and workouts come only from the pasted plan or the editor. Typed foods
  are remembered per meal slot.
- **Game layer:** points per day from workout, food, water, sleep and run (`models/game.dart`), levels
  from lifetime points, 20 badges (`models/badges.dart`). All derived from logs, never stored.
- **Tabs:** Home (web radar), Workout, Meals, Run, Progress. Weigh-in lives under Progress.
- **Effects:** web-shot animation and sounds (`widgets/web_shot.dart`, `services/sfx.dart`, SoundPool in
  `MainActivity.kt`), muted from Profile.
- **Design system:** `theme/app_theme.dart` (matte black, red accent, blue data, IBM Plex bundled in
  `assets/google_fonts/`). Flat rows and hairline `Panel`s, not cards.
- **Schema v5:** workout, meal, weight, run, wellness, custom_item, plan_store, settings, app_state.
- **Build:** needs JDK 17 (`flutter config --jdk-dir`). `python3 tools/make_logo.py` regenerates the icon.
- **Not done:** widget tests beyond loading states and the plan editor; CSV export (V2); meal slot times
  and the auto-flag keyword list are still fixed in code.
