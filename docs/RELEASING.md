# Releasing

The APK is published as a GitHub Release asset. A workflow builds it for you
whenever you push a version tag.

## Cut a release

1. Bump `version:` in `pubspec.yaml` (for example `1.8.0+10`; the number after
   `+` is the Android build number and must increase every release).
2. Update `CHANGELOG.md`.
3. Commit, then tag with the same version and push the tag:

   ```bash
   git commit -am "Release 1.8.0"
   git tag v1.8.0
   git push origin main --tags
   ```

4. Open the **Actions** tab and wait for **Build APK** to finish (about 5-8
   minutes). It creates the release and attaches `Spider-Tracker.apk` and
   `Spider-Tracker.apk.sha256`.

The stable file name means this link always serves the newest APK:
`https://github.com/Karan1114Anand/SpiderTracker-FitnessTracker/releases/latest/download/Spider-Tracker.apk`

## Sign releases with your own key (recommended)

Without a key, builds are signed with a debug key. That installs fine, but a
debug key differs between machines, so an APK built on one machine cannot update
an install made from another. Use one permanent key.

1. Create a keystore once and **back it up somewhere private**. If you lose it
   you can never ship an update over existing installs.

   ```bash
   keytool -genkeypair -v -keystore spider-tracker-release.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias spider
   ```

2. Local builds: create `android/key.properties` (git-ignored):

   ```properties
   storeFile=/absolute/path/to/spider-tracker-release.jks
   storePassword=YOUR_STORE_PASSWORD
   keyAlias=spider
   keyPassword=YOUR_KEY_PASSWORD
   ```

3. GitHub builds: in the repository go to **Settings, Secrets and variables,
   Actions, New repository secret** and add:

   | Secret | Value |
   |---|---|
   | `ANDROID_KEYSTORE_BASE64` | output of `base64 -w0 spider-tracker-release.jks` |
   | `ANDROID_KEYSTORE_PASSWORD` | your store password |
   | `ANDROID_KEY_ALIAS` | `spider` |
   | `ANDROID_KEY_PASSWORD` | your key password |

Never commit the `.jks` file or `key.properties`; both are git-ignored.

## Build a release APK locally

```bash
flutter build apk --release
mkdir -p dist
cp build/app/outputs/flutter-apk/app-release.apk dist/Spider-Tracker.apk
(cd dist && sha256sum Spider-Tracker.apk > Spider-Tracker.apk.sha256)
```
