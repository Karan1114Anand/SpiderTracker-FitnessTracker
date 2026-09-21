# Spider-Tracker

A fitness tracker for Android that keeps everything on your phone. You tell it
about yourself, an AI assistant of your choice (or you) builds the plan, and the
app turns your daily habits into points, levels and badges.

**No account. No cloud. No internet permission.** The release APK does not
request network access at all, so your data cannot leave the device.

## Download

**[Download the latest APK](https://github.com/Karan1114Anand/SpiderTracker-FitnessTracker/releases/latest/download/Spider-Tracker.apk)**
· [All releases](https://github.com/Karan1114Anand/SpiderTracker-FitnessTracker/releases)
· [SHA-256 checksum](https://github.com/Karan1114Anand/SpiderTracker-FitnessTracker/releases/latest/download/Spider-Tracker.apk.sha256)

Requires Android 7.0 (API 24) or newer.

### Install

1. Open the download link on your phone (or copy the file to it).
2. Tap the downloaded `Spider-Tracker.apk`.
3. If Android asks, allow installs from your browser or file manager
   (Settings, Install unknown apps). This is needed because the app isn't
   on the Play Store.
4. Open **Spider-Tracker** and complete sign-up.

Prefer to verify the file first? Compare its SHA-256 with the `.sha256` file:

```bash
sha256sum -c Spider-Tracker.apk.sha256
```

## What it does

- **Personal plan.** Sign up with your name, age, height, weight, goal and the
  kind of workouts you can do. The app writes a prompt for you. Paste it into
  any AI assistant, paste the reply back, and your workout week and meal
  options are set. Or skip the AI and build your workout week by hand.
- **Daily tracking.** Log workout sets, meals (pick from your plan or type your
  own), water, sleep and runs. Weigh in weekly.
- **Points, levels and badges.** Each habit earns points toward a daily total of
  112. Points add up to levels, and 20 badges mark milestones such as streaks,
  hydration, sleep, running and weight goals. There is no calorie counting.
- **Web radar.** Home shows today's five habits as a web that fills in as you
  log, so the weakest habit is obvious at a glance.
- **Progress.** Weight trend against a realistic range, a 12-week consistency
  grid and diet history.
- **Effects.** A web-shot animation with a sound on key actions. Mute it from
  Profile.

## Privacy

- All data lives in a local SQLite database on your phone.
- The app has no analytics, no accounts and no network permission.
- The only thing that ever leaves your phone is the prompt **you** choose to
  paste into an AI assistant, and the reply you paste back.
- Delete everything at any time from Profile, or by uninstalling the app.

## Build from source

Requirements: Flutter 3.35 (stable) and JDK 17.

```bash
git clone https://github.com/Karan1114Anand/SpiderTracker-FitnessTracker.git
cd SpiderTracker-FitnessTracker
flutter pub get
flutter test
flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk
```

A JDK newer than 17 can break the Gradle build; if `flutter doctor` picks the
wrong one, run `flutter config --jdk-dir /path/to/jdk17`.

Releases and signing are described in [docs/RELEASING.md](docs/RELEASING.md).
The code layout is in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Contributing

Issues and pull requests are welcome. Please run `flutter analyze` and
`flutter test` before opening a pull request.

## License

[MIT](LICENSE). The bundled IBM Plex fonts are under the
[SIL Open Font License](assets/google_fonts/LICENSE-IBM-Plex.txt).
