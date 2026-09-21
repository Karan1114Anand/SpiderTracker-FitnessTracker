# Spider-Tracker

Spider-Tracker is an Android app for tracking workouts, meals, water, sleep, runs
and weight. It stores everything on the phone and scores each day with points, so
progress does not depend on counting calories.

The workout plan and meal options are not built into the app. You describe
yourself once, the app writes a prompt, and you paste the reply from any AI
assistant back into the app. If you prefer, you can build the workout week by
hand and skip the assistant.

## Download

Latest release: [Spider-Tracker.apk](https://github.com/Karan1114Anand/SpiderTracker-FitnessTracker/releases/latest/download/Spider-Tracker.apk)
([checksum](https://github.com/Karan1114Anand/SpiderTracker-FitnessTracker/releases/latest/download/Spider-Tracker.apk.sha256),
[all releases](https://github.com/Karan1114Anand/SpiderTracker-FitnessTracker/releases))

The app needs Android 7.0 (API 24) or later.

### Installing

1. Download the APK on your phone, or copy it there.
2. Open the file. Android will ask you to allow installs from the app you opened
   it with (a browser or file manager). The setting is under Install unknown
   apps. The prompt appears because the app is not distributed through the
   Play Store.
3. Open Spider-Tracker and enter your details.

To check the download, compare its SHA-256 hash with the published checksum:

```bash
sha256sum -c Spider-Tracker.apk.sha256
```

## Using it

Setup asks for your name, age, height, current and goal weight, the number of
weeks you are giving yourself, the kind of training you can do, how many days a
week, and any dietary notes. From those it writes a prompt. Paste the prompt into
an assistant of your choice, then paste the reply into the app. The app checks the
reply and tells you what is wrong if it cannot use it. You can redo this later from
the Profile screen without losing your logs.

Each day you can log:

- workout sets, checked off exercise by exercise
- meals, chosen from your plan or typed in, then rated good, okay or cheat
- water, in 250 ml steps
- hours of sleep
- a run, as distance and time
- your weight, once a week

### Points, levels and badges

A day is worth up to 112 points: 30 for the workout, 32 for food, 15 for water,
15 for sleep and 20 for a run. Water counts toward a 3 litre target and sleep
toward 7 hours. Lifetime points set your level, and there are 20 badges for
streaks, hydration, sleep, running, points and weight milestones. All of this is
calculated from your logs when needed, so correcting a log corrects the totals.

The Home screen draws the five habits as a web that fills in as you log, which
makes the weakest habit of the day easy to see. The Progress screen shows your
weight against a realistic range, a 12 week consistency grid and your recent diet
scores.

## Privacy

Data is kept in a SQLite database on the device. The release build does not
request the Android internet permission, so the app cannot send anything anywhere.
The only text that leaves the phone is the prompt you decide to paste into an
assistant. There are no accounts, analytics or advertising.

Because nothing is backed up, uninstalling the app or clearing its storage
deletes your data. You can also erase it from the Profile screen.

## Limitations

- Android only.
- There is no export or backup yet.
- Meal times shown in the app are fixed, and the list of words that flags a typed
  food as a cheat is short and leans toward Indian and fast-food items.
- The points system is the same for everyone and is not medical advice. Check
  your goals with a doctor or dietitian if you have a health condition.

## Building from source

You need Flutter 3.35 (stable) and JDK 17. Newer JDKs can break the Gradle build.
If Flutter picks the wrong one, point it at the right one with
`flutter config --jdk-dir <path>`.

```bash
git clone https://github.com/Karan1114Anand/SpiderTracker-FitnessTracker.git
cd SpiderTracker-FitnessTracker
flutter pub get
flutter test
flutter build apk --release
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`.
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) describes the code layout and
[docs/RELEASING.md](docs/RELEASING.md) covers signing and publishing a release.

## Contributing

Bug reports and pull requests are welcome. Run `flutter analyze` and
`flutter test` before opening a pull request.

## License

The code is released under the [MIT License](LICENSE). The bundled IBM Plex fonts
are licensed under the [SIL Open Font License](assets/google_fonts/LICENSE-IBM-Plex.txt).
