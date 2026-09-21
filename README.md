# Spider-Tracker

Personal fitness and diet tracker for Karan Anand. Local-only Flutter Android app —
no login, no server, no network. Goal: 95 kg → 82.5 kg by 2026-12-01.

**Start here: [`PROJECT_GRAPH.md`](PROJECT_GRAPH.md)** — full state of the project,
what's done, what's left, and the conventions to keep.
Scope contract: [`docs/PRD.md`](docs/PRD.md).

## Running it

The Flutter SDK is not on PATH on this machine:

```bash
export PATH="$PATH:/home/klaus/devtools/flutter/bin"
cd /home/klaus/Projects/Spider-Tracker

flutter analyze     # clean as of 2026-09-22
flutter test        # 23 passing
flutter run         # device or emulator
```

### Web preview

Runs against IndexedDB, not SQLite — preview only, data does not carry to the phone.
Requires `web/sqlite3.wasm` and `web/sqflite_sw.js`, both already present. Without them
the app hangs on a silent splash forever.

```bash
flutter run -d chrome
```

### APK

Not yet built. Change `applicationId`, `android:label` and the launcher icon first —
see B3 in `PROJECT_GRAPH.md`.

```bash
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```
