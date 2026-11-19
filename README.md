# Khmer Digital Bank

Digital banking for Cambodia — Khmer / English, USD / KHR.

| Part | Location | Stack |
|---|---|---|
| Mobile app | [`lib/`](lib/) | Flutter, BLoC, go_router, Dio, get_it |
| Backend API | [`backend/`](backend/) | Java 21, Spring Boot 3, PostgreSQL, Redis, Flyway, JWT |
| Admin dashboard | — | Phase 9 (planned) |

**Docs:** [Architecture & roadmap](docs/ARCHITECTURE.md) · [Database / ER](docs/DATABASE.md) ·
[REST API](docs/API.md) · [Setup, testing & deployment](docs/SETUP.md)

> ⚠️ This project does **not** have KHQR / Bakong, card-network, biller or telco connectivity.
> Those integrations are defined as interfaces and require licensed, authorized credentials.
> Money added through the dev-only deposit endpoint is **SIMULATED** and flagged as such.

Quick start: `cp .env.example .env`, fill in secrets, `docker compose up --build`, then
press F5 → `dev · debug` in VS Code (or `flutter run --flavor dev --dart-define-from-file=config/env/dev.json`).

## Flavors (environments)

The app has five flavors. Each one installs as its own app, so you can have several on one
device at the same time. Each also uses its own Firebase app in the `khmer-flutter-bank` project.

| Flavor | Bundle / package ID | App name |
|---|---|---|
| `dev` | `com.khmerflutterbank.dev` | Khmer Bank Dev |
| `sit` | `com.khmerflutterbank.sit` | Khmer Bank SIT |
| `uat` | `com.khmerflutterbank.uat` | Khmer Bank UAT |
| `preprod` | `com.khmerflutterbank.preprod` | Khmer Bank Pre-Prod |
| `prod` | `com.khmerflutterbank` | Khmer Bank |

### Environment values

Settings that differ between environments are kept in `config/env/<flavor>.json` and passed in
with `--dart-define-from-file`. Currently the only setting is `API_BASE_URL`:

```json
{ "API_BASE_URL": "https://uat-api.example.com/api/v1" }
```

> Replace the placeholder `example.com` URLs in `sit`, `uat`, `preprod` and `prod` with the real
> backends. `dev` points to `http://10.0.2.2:8080/api/v1`, the local backend as seen from the
> Android emulator.

### Run, debug & build

**VS Code (recommended).** These configurations pass `--flavor` and the matching env file for you.

| What | How |
|---|---|
| Debug / run | **Run and Debug** panel (F5), then pick e.g. `uat · debug`, `uat · release`, `prod · profile` |
| Build | **Ctrl+Shift+B**, then pick the target (`apk` / `appbundle` / `ios` / `ipa`), environment and mode |
| Other tasks | **Terminal → Run Task…**: `run`, `pub get`, `analyze`, `test`, `clean` |

These come from [`.vscode/launch.json`](.vscode/launch.json) and [`.vscode/tasks.json`](.vscode/tasks.json).

**Flutter CLI.** Android has no default flavor, so always pass `--flavor`:

```bash
flutter run   --flavor uat --dart-define-from-file=config/env/uat.json                    # debug
flutter run   --flavor uat --release --dart-define-from-file=config/env/uat.json          # release on device
flutter run   --flavor prod --profile --dart-define-from-file=config/env/prod.json        # profile (performance)
flutter build apk       --flavor uat  --release --dart-define-from-file=config/env/uat.json
flutter build appbundle --flavor prod --release --dart-define-from-file=config/env/prod.json
flutter build ipa       --flavor prod --dart-define-from-file=config/env/prod.json   # macOS only
```

| Mode | Use for |
|---|---|
| `debug` | Development: hot reload and debugger, slow |
| `profile` | Measuring performance (DevTools); real devices only |
| `release` | Testers and the stores: optimized, no debugger |

Output files:
- APK: `build/app/outputs/flutter-apk/app-<flavor>-release.apk`
- AAB: `build/app/outputs/bundle/<flavor>Release/app-<flavor>-release.aab`
- IPA: `build/ios/ipa/`

In Xcode, select the matching scheme (`dev`, `sit`, `uat`, `preprod`, `prod`). Building the
plain `Runner` scheme gives you prod.

> Release builds are currently signed with the **debug key**
> (`signingConfig = signingConfigs.getByName("debug")` in `android/app/build.gradle.kts`).
> Set up a real upload keystore before publishing to Google Play.

### How it works

| Piece | Location |
|---|---|
| Android flavors | `productFlavors` in [`android/app/build.gradle.kts`](android/app/build.gradle.kts) |
| Android Firebase config | `android/app/src/<flavor>/google-services.json` |
| iOS build configurations | `Debug-<flavor>` / `Release-<flavor>` / `Profile-<flavor>`, with xcconfigs in `ios/Flutter/` |
| iOS schemes | `ios/Runner.xcodeproj/xcshareddata/xcschemes/<flavor>.xcscheme` |
| iOS Firebase config | `ios/config/<flavor>/GoogleService-Info.plist` (a build step copies it into the app) |
| Dart Firebase options | `lib/firebase_options_<flavor>.dart` |
| Flavor selection in Dart | [`lib/app/flavor.dart`](lib/app/flavor.dart) reads `appFlavor` and calls `Firebase.initializeApp` |

In Dart, use `currentFlavor` (for example `currentFlavor.isProd`) for anything that differs
between environments.

### Re-generate a flavor's Firebase config

```bash
flutterfire configure --yes --project=khmer-flutter-bank \
  --out=lib/firebase_options_uat.dart --platforms=android,ios \
  --ios-bundle-id=com.khmerflutterbank.uat --android-package-name=com.khmerflutterbank.uat \
  --android-out=android/app/src/uat/google-services.json \
  --ios-out=ios/config/uat/GoogleService-Info.plist
```

The trailing `\` line breaks work in bash only. In PowerShell, end each line with a backtick
(`` ` ``) or put the whole command on one line.

On Windows, `flutterfire` does not write the iOS plist. Download it with
`firebase apps:sdkconfig IOS <ios-app-id> --project=khmer-flutter-bank --out ios/config/uat/GoogleService-Info.plist`
(the iOS app ID is listed in `firebase.json`).

The older coupon/promotion demo screens remain under `lib/coupon`, `lib/coins`, `lib/store`, etc.
