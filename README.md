# valuex-mobile

ValueX C2C marketplace mobile app (Flutter). Targets Android and iOS; a `web/` runner exists for quick UI checks only.

## Tech stack

| Area | Library |
|---|---|
| State management | `flutter_riverpod`, `riverpod_annotation` / `riverpod_generator` |
| Navigation | `go_router` |
| Networking | `dio` |
| Storage | `shared_preferences`, `flutter_secure_storage` |
| UI | `flutter_svg`, `cached_network_image`, `shimmer`, Inter font |
| Media / permissions | `image_picker`, `permission_handler` |
| Utilities | `intl`, `uuid`, `logger` |
| Lint | `flutter_lints`, `riverpod_lint` |

## Prerequisites

- Flutter `>= 3.22.0` (stable) with Dart `>= 3.4.0 < 4.0.0`
- Git
- Android: Android Studio, Android SDK + platform tools, an emulator or USB device, JDK 17 (Gradle and Kotlin target Java 17). If several JDKs are installed, point Gradle at 17 on your machine only, in `~/.gradle/gradle.properties` (not in the repo): `org.gradle.java.home=/path/to/jdk-17`
- iOS (macOS only): Xcode (latest stable) with command line tools, CocoaPods (`brew install cocoapods`), iOS 15.0+ simulator or device
- For API-backed features: the `valuex-backend` service running locally (see [Backend](#backend))

Verify the toolchain:

```bash
flutter --version
flutter doctor -v
```

All items relevant to your target platform should be green.

## Setup

```bash
cd valuex-mobile
flutter pub get

# iOS only
cd ios && pod install && cd ..
```

Fonts (`assets/fonts/`) and images (`assets/images/`) are checked in. When adding assets, register them in `pubspec.yaml` and re-run `flutter pub get`.

## Running the app

The app reads its environment from a JSON file passed with `--dart-define-from-file`. Without it the app stops at startup with a configuration error.

```bash
flutter devices                                                    # list emulators/simulators/devices
flutter run -d <device-id> --dart-define-from-file=config/dev_android.json   # Android emulator
flutter run -d <device-id> --dart-define-from-file=config/dev_ios.json       # iOS simulator
```

| File | Use | `API_BASE_URL` |
|---|---|---|
| `config/dev_android.json` | Android emulator | `http://10.0.2.2:8080/api/v1` |
| `config/dev_ios.json` | iOS simulator | `http://localhost:8080/api/v1` |
| `config/dev_local.json` | physical device (git-ignored, create it yourself) | `http://<your-LAN-IP>:8080/api/v1` |
| `config/staging.json` | staging | placeholder host, replace before use |
| `config/prod.json` | production | placeholder host, replace before use |

Keys: `ENV` (`dev`, `staging`, `prod`), `API_BASE_URL` (https outside dev), `AADHAAR_FLOW` (`sandbox` or `thirdparty`; `sandbox` is rejected in prod), `GOOGLE_SIGN_IN` (`mock` or `native`; `mock` is rejected in prod and is the default), `GOOGLE_SERVER_CLIENT_ID` (required for `native`) and `GOOGLE_IOS_CLIENT_ID` (optional). The files hold public values only, never secrets. The same flag works for `flutter build`. VS Code launch entries are in `.vscode/launch.json`.

Hot reload: `r`, hot restart: `R`, quit: `q`.

## Google sign-in

With `GOOGLE_SIGN_IN=mock` (all dev configs) "Continue with Google" opens a development-only chooser and sends `mock-<name>` to a backend running the mock verifier (`valuex.oauth.google.provider=mock`, the backend default). The same name always maps to the same Google account, so use a new name to act as a new user.

With `native` the app shows the real Google account chooser (`google_sign_in`) and sends the ID token to the backend, which verifies it. One-time setup in Google Cloud Console:

1. Create OAuth clients: **Web** (its ID is `GOOGLE_SERVER_CLIENT_ID`, the token audience the backend must list in `GOOGLE_CLIENT_ID_WEB`), **Android** (package `com.valuex.valuex_mobile` plus the SHA-1 of each signing key, debug and release) and **iOS** (bundle ID `com.valuex.valuexMobile`).
2. Put the iOS client ID in `GOOGLE_IOS_CLIENT_ID` and add its reversed form as a URL scheme in `ios/Runner/Info.plist` (`CFBundleURLTypes`, scheme `com.googleusercontent.apps.<id>`).
3. Start the backend with `GOOGLE_OAUTH_PROVIDER=http` and all three client IDs.

Nothing is stored on the device for Google itself; the app signs the Google account out right after reading the token.

## Backend

Start the backend (Spring Boot, port `8080`, `dev` profile) from `valuex-backend/`. See [../valuex-backend/README.md](../valuex-backend/README.md) for details. PostgreSQL and Redis are provided by `valuex-backend/docker-compose.yml`:

```bash
cd ../valuex-backend
docker compose up -d
```

Swagger UI (dev profile): `http://localhost:8080/swagger-ui.html`.

Android note: cleartext HTTP is allowed in debug and profile builds only (needed for `10.0.2.2`). Release builds must use HTTPS. iOS allows local-network HTTP through `NSAllowsLocalNetworking`.

## Profile Management (US-003)

Home's Profile tab opens `/profile` for signed-in users; guests are routed to Sign In.
The page follows the Figma Make `ProfileScreen`: a header (avatar, name with a verified mark,
masked mobile, rating, transactions, city, edit button), the plan badge or Upgrade to Premium
invite, the Listings/Sold/Reviews tiles, the Buying, Selling and Account menus, Sign Out and the
main navigation. Menu rows and Upgrade are not built yet and answer with a passing
"coming soon" message. Rating, transactions, listings, sold and plan come from
`profileSummaryProvider` (`lib/features/profile/data/mock_profile_summary.dart`), which returns the
mock values from Figma Make. Replace that provider with real data when the ratings, orders,
listing and subscription stories are built.

The edit button opens `/profile/details`, which reads `GET /users/me`, shows the server's masked
mobile/email and joined date, and keeps verified Aadhaar name and other identity/address fields
read-only. Edit profile sends only changed display-name/city fields with `PATCH /users/me`.

Change avatar reads `GET /avatars`, displays only the returned catalog IDs using the existing
bundled avatar renderer, and requires confirmation before `PUT /users/me/avatar`. A removed
avatar remains displayed until another is selected; a rejected selection preserves the current
avatar. Failed edits retain the draft, and leaving an edited profile asks before discarding changes.

The backend only validates city format, not Indian geography. Ratings and viewing another user's
profile are deferred backend capabilities. Security settings remain
US-103/US-105 work. The existing avatar illustrations are placeholders pending final artwork.
Backend profile PATCH validation also differs from registration for Unicode combining marks;
server rejections are displayed rather than treated as successful saves.

Verification: `flutter test test/features/profile/profile_test.dart` covers repository payloads,
navigation, retry, partial edits, avatar confirmation/rejection, accessibility and large-text layout.
For manual testing, use an existing authenticated account, open Profile, edit one field, save,
reopen and confirm persistence. Cancel a changed draft, try invalid names/cities, and test avatars
with a modified server catalog. Do not reset the simulator Keychain to switch test users; use the
debug-only `CLEAR_LOCAL_SESSION` launch flag.

## Account Logout (US-104)

Profile's Sign Out row asks "Are you sure you want to log out?". Confirming shows a progress
indicator while `POST /auth/logout` revokes the access token (the backend blocklists its `jti`,
which also invalidates the paired refresh token). The device is then signed out and the router
sends the user to Sign In. Cancel keeps the session.

The device is always signed out, even if the call fails:

- **Offline or server error (network, timeout, 5xx):** the access token is kept in secure
  storage as a one-shot "pending revocation" record and a message says the server sign-out will
  finish when the phone is back online. `SessionController` retries it with an explicit bearer
  token (no refresh) on the next app start and after the next sign-in. It is dropped on success
  or when the server no longer accepts it (401). Trade-off: until then, that access token
  (valid for 1 h at most) stays on the device.
- **Expired session (401):** treated as already logged out.

Logout also clears the saved Home address and any unfinished sign-up state so the next person
on a shared device does not see them (`LogoutAction`). The "session expired" notice is
suppressed during a deliberate logout.

Verification: `flutter test test/features/profile/profile_test.dart
test/features/auth/data/auth_data_test.dart
test/features/auth/presentation/session_controller_test.dart test/core/network/api_client_test.dart`.
Manual: sign in, open Profile, Sign Out, confirm you land on Sign In and that reopening the
app stays signed out; with the backend stopped, repeat and check the "finish signing you out"
message, then restart the backend and the app and confirm the old token is rejected.

## Project structure

```
config/                     # Per-environment JSON for --dart-define-from-file
lib/
  main.dart                 # Entry point, reads AppConfig, wraps app in ProviderScope
  app.dart                  # ValueXApp: theme, router and localization wiring
  l10n/                     # app_en.arb, app_hi.arb and generated AppLocalizations
  core/
    config/                 # app_config (environment values)
    constants/              # api_constants, app_constants, storage_keys
    network/                # api_client, api_interceptor (refresh once on 401), api_error, api_response
    routing/                # go_router config (app_router), route_names, route_guard (redirect by account status)
    security/               # secure_storage_service (tokens)
    storage/                # preferences_service (non-sensitive flags)
    theme/                  # colors, text_styles, app_theme
    utils/                  # date_utils, formatters, validators
    widgets/                # shared widgets (buttons, back button, logo, error view, ...)
  features/
    splash/presentation/
    onboarding/presentation/
    auth/                   # data/, domain/, presentation/ (providers, screens, widgets)
    home/presentation/
test/                       # Unit and widget tests mirroring lib/
```

Conventions for new work:

- One folder per feature under `lib/features/<feature>/` with `presentation/` and, as needed, `data/` and `domain/`.
- Reusable widgets go in `lib/core/widgets/` or `lib/features/<feature>/presentation/widgets/`; app-wide helpers in `lib/core/`.
- User-facing text goes in `lib/l10n/app_en.arb` and `app_hi.arb`, then run `flutter gen-l10n`; read it with `AppLocalizations.of(context)`. No hardcoded strings in widgets.
- Register routes in `route_names.dart` and `app_router.dart`.
- Keep tokens in `SecureStorageService`; non-sensitive flags in `PreferencesService`. Keys live in `storage_keys.dart`.
- Make HTTP calls through `ApiClient` so timeouts (30 s) and error mapping stay consistent.
- Follow [../Documents/CODING_STANDARDS.md](../Documents/CODING_STANDARDS.md).
- Follow the UI rules in [docs/Flutter-Design-System.md](docs/Flutter-Design-System.md) for every screen: tokens, fonts, buttons, and the approval step for any Figma value that conflicts with them.

## Code generation (Riverpod)

When using `@riverpod` annotations:

The project uses Riverpod 3 with `riverpod_generator` 3; older generators cannot analyze the current Dart SDK. Generated `.g.dart` files are committed.

```bash
dart run build_runner build --delete-conflicting-outputs   # one-off
dart run build_runner watch --delete-conflicting-outputs   # during development
```

Add `part 'file_name.g.dart';` to files that use annotations.

## Testing

```bash
flutter test                              # all tests
flutter test test/widget_test.dart        # single file
flutter test --coverage                   # report at coverage/lcov.info
```

Integration tests (registration and Sign In end to end with an in-memory server; need an emulator or simulator, and replace the installed app):

```bash
flutter test integration_test -d <device-id>
```

The same scenarios also run on the host: copy `integration_test/registration_flow_test.dart` (or `sign_in_flow_test.dart`) into `test/`, change the `../test/helpers/` imports to `helpers/`, run it, then delete the copy.

Optional HTML coverage report (`brew install lcov`):

```bash
genhtml coverage/lcov.info -o coverage/html && open coverage/html/index.html
```

Guidelines:

- Mirror the `lib/` structure under `test/` (e.g. `test/core/utils/validators_test.dart`).
- Wrap widgets under test in `ProviderScope` and override providers to mock API and storage.
- Do not hit the real backend in unit or widget tests. `test/helpers/app_harness.dart` runs the real app against a mocked repository; `test/helpers/fake_auth_repository.dart` is an in-memory server for whole flows.
- Layout tests load the bundled fonts (`test/helpers/fonts.dart`); the default test font is much wider than DM Sans.

Manual test guides per user story and sprint are in [../Documents](../Documents) (`Manual Testing Guides/`, `Sprint-1-Combined-Testing-Guide.md` with the US-106 mobile scenarios, `Sprint-1-OTP-Regression-Checklist.md`).

## Static analysis and formatting

```bash
flutter analyze --fatal-infos
dart format lib test integration_test
dart format --output=none --set-exit-if-changed lib test integration_test   # CI-style check
```

Rules come from `flutter_lints` and `riverpod_lint` ([analysis_options.yaml](analysis_options.yaml); `riverpod_lint` is enabled under `plugins:`, and the first analyze downloads it). Resolve all analyzer issues, infos included, before opening a PR.

## Continuous integration

[.github/workflows/mobile-ci.yml](.github/workflows/mobile-ci.yml) runs on every pull request and on `main`:

| Job | Checks |
|---|---|
| `pr-title` | Conventional Commits title |
| `quality` | generated code up to date, format, `flutter analyze --fatal-infos`, tests, coverage gate (85%, generated and l10n files excluded) |
| `store-compliance` | `tool/check_store_compliance.sh` (see below) |
| `android-build` | debug APK |
| `ios-build` | debug iOS build without signing, only when `ios/` or the pubspec files change |

The Flutter version is pinned in the workflow (`FLUTTER_VERSION`); update it deliberately. Run the same checks locally before pushing:

```bash
dart run build_runner build --delete-conflicting-outputs && flutter gen-l10n && dart format lib test integration_test && git diff --exit-code -- lib
flutter test --coverage && tool/check_coverage.sh coverage/lcov.info 85
```

CI adds `--dart-define=SKIP_PIXEL_CONTRAST=true` to `flutter test`: the framework's pixel-sampling text-contrast check reads thin text as far lighter on the Linux runner than on macOS, so it only runs locally. Token contrast is enforced on every platform by `test/core/theme/contrast_test.dart`. Major-version dependency upgrades are not proposed by Dependabot; do them deliberately.

## Store compliance

`tool/check_store_compliance.sh` checks what can be verified from the repo for Google Play and the App Store (release signing, privacy manifest, encryption declaration, permissions, usage strings, placeholder hosts). It reports findings as warnings; `--strict` (or the `strict_store_checks` input of a manual CI run) fails on any finding. The manual checklist and current gaps are in [docs/Store-Compliance.md](docs/Store-Compliance.md).

## Building

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS (configure signing in ios/Runner.xcworkspace first)
flutter build ios --release
```

Application ID / bundle ID: `com.valuex.valuex_mobile`. Version is set by `version:` in `pubspec.yaml` (`name+buildNumber`).

## Troubleshooting

| Problem | Fix |
|---|---|
| Stale dependencies or odd build errors | `flutter clean && flutter pub get` |
| iOS pod errors | `cd ios && pod install --repo-update` |
| Android Gradle failures | Confirm JDK 17 (`flutter doctor -v`); with several JDKs installed, set `org.gradle.java.home` in `~/.gradle/gradle.properties`, then `cd android && ./gradlew clean` |
| Android licence errors | `flutter doctor --android-licenses` |
| API unreachable from Android emulator | Use `10.0.2.2` instead of `localhost` |
| API unreachable in Android release build | Add the `INTERNET` permission to the main manifest |
| Missing `*.g.dart` files | Run the `build_runner` command above |
| Missing splash/onboarding images or fonts | Check `assets/` entries in `pubspec.yaml`, then `flutter pub get` |

## Git hygiene

- Do not commit `build/`, `.dart_tool/`, `android/local.properties`, or IDE files.
- Commit `pubspec.lock`.
- Run `flutter analyze` and `flutter test` before every push (CI runs both, plus the other checks above).
