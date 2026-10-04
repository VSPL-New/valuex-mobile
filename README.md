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
- Android: Android Studio, Android SDK + platform tools, an emulator or USB device, JDK 17 (Gradle and Kotlin target Java 17)
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

```bash
flutter devices                 # list emulators/simulators/devices
flutter run                     # run on the default device
flutter run -d <device-id>      # run on a specific device
flutter run -d chrome           # web (UI checks only; secure storage/permissions are limited)
```

Hot reload: `r`, hot restart: `R`, quit: `q`.

## Backend

The API base URL is hardcoded in [lib/core/constants/api_constants.dart](lib/core/constants/api_constants.dart):

```dart
static const String baseUrl = 'http://localhost:8080/api/v1';
```

`localhost` only reaches your machine from the iOS simulator and web. Change the host per target:

| Target | Host |
|---|---|
| iOS simulator / web | `localhost` |
| Android emulator | `10.0.2.2` |
| Physical device | your machine's LAN IP (same network) |

Revert local host changes before committing.

Start the backend (Spring Boot, port `8080`, `dev` profile) from `valuex-backend/`. See [../valuex-backend/README.md](../valuex-backend/README.md) for details. PostgreSQL and Redis are provided by `valuex-backend/docker-compose.yml`:

```bash
cd ../valuex-backend
docker compose up -d
```

Swagger UI (dev profile): `http://localhost:8080/swagger-ui.html`.

Android note: the main `AndroidManifest.xml` does not declare `android.permission.INTERNET`; only the debug/profile manifests do. Add it to `android/app/src/main/AndroidManifest.xml` before producing release builds that call the API. Cleartext HTTP is not configured either, so use HTTPS outside local development.

## Project structure

```
lib/
  main.dart                 # Entry point, wraps app in ProviderScope
  app.dart                  # ValueXApp: theme and router wiring
  core/
    constants/              # api_constants, app_constants, storage_keys
    network/                # Dio api_client, api_response, api_error
    routing/                # go_router config (app_router), route_names
    storage/                # preferences_service, secure_storage_service
    theme/                  # colors, text_styles, app_theme
    utils/                  # date_utils, formatters, validators
  features/
    splash/presentation/
    onboarding/presentation/
    home/presentation/
  shared/widgets/           # app_button, app_text_field, error_view, loading_indicator
test/                       # Widget and unit tests
```

Conventions for new work:

- One folder per feature under `lib/features/<feature>/` with `presentation/` and, as needed, `data/` and `domain/`.
- Reusable widgets go in `lib/shared/widgets/`; app-wide helpers in `lib/core/`.
- Register routes in `route_names.dart` and `app_router.dart`.
- Keep tokens in `SecureStorageService`; non-sensitive flags in `PreferencesService`. Keys live in `storage_keys.dart`.
- Make HTTP calls through `ApiClient` so timeouts (30 s) and error mapping stay consistent.
- Follow [../Documents/CODING_STANDARDS.md](../Documents/CODING_STANDARDS.md).
- Follow the UI rules in [docs/Flutter-Design-System.md](docs/Flutter-Design-System.md) for every screen: tokens, fonts, buttons, and the approval step for any Figma value that conflicts with them.

## Code generation (Riverpod)

When using `@riverpod` annotations:

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

Optional HTML coverage report (`brew install lcov`):

```bash
genhtml coverage/lcov.info -o coverage/html && open coverage/html/index.html
```

Guidelines:

- Mirror the `lib/` structure under `test/` (e.g. `test/core/utils/validators_test.dart`).
- Wrap widgets under test in `ProviderScope` and override providers to mock API and storage.
- Do not hit the real backend in unit or widget tests.

Manual test guides per user story and sprint are in [../Documents](../Documents), e.g. `US-001-Testing-Guide.md`, `Sprint-1-Combined-Testing-Guide.md`, `Sprint-1-OTP-Regression-Checklist.md`.

## Static analysis and formatting

```bash
flutter analyze
dart format lib test
dart format --output=none --set-exit-if-changed lib test   # CI-style check
```

Rules come from `flutter_lints` ([analysis_options.yaml](analysis_options.yaml)). Resolve all analyzer issues before opening a PR.

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
| Android Gradle failures | Confirm JDK 17 (`flutter doctor -v`), then `cd android && ./gradlew clean` |
| Android licence errors | `flutter doctor --android-licenses` |
| API unreachable from Android emulator | Use `10.0.2.2` instead of `localhost` |
| API unreachable in Android release build | Add the `INTERNET` permission to the main manifest |
| Missing `*.g.dart` files | Run the `build_runner` command above |
| Missing splash/onboarding images or fonts | Check `assets/` entries in `pubspec.yaml`, then `flutter pub get` |

## Git hygiene

- Do not commit `build/`, `.dart_tool/`, `android/local.properties`, or IDE files.
- Commit `pubspec.lock`.
- Run `flutter analyze` and `flutter test` before every push.
