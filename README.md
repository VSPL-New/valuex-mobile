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

Keys: `ENV` (`dev`, `staging`, `prod`), `API_BASE_URL` (https outside dev), `AADHAAR_FLOW` (`sandbox` or `thirdparty`; `sandbox` is rejected in prod), `GOOGLE_SIGN_IN` (`mock` or `native`; `mock` is rejected in prod and is the default), `GOOGLE_SERVER_CLIENT_ID` (required for `native`) and `GOOGLE_IOS_CLIENT_ID` (optional), `ADDRESS_SEARCH` (`mock` or `google`; `mock` is the default and is rejected in prod) and `GOOGLE_PLACES_API_KEY` (required for `google`). The files hold public values only, never secrets. The same flag works for `flutter build`. VS Code launch entries are in `.vscode/launch.json`.

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

## Profile Hub (US-103)

The Profile tab is the account menu. It reads `GET /users/me/menu-summary` on every visit (and on
pull down) and shows a count pill on each row whose key is in the response `badges` map:
My Orders `MY_ORDERS`, Saved Items `SAVED_ITEMS`, Payment History `TRANSACTIONS`, Incoming Orders
`INCOMING_ORDERS`, My Listings `MY_LISTINGS`, Payout Details `PAYOUTS`, Notifications
`NOTIFICATIONS`, Dispute Center `DISPUTES`, Help & Support `SUPPORT_TICKETS` (keys from LLD Sprint 1
section 8.3). The backend returns a key only once its story ships, so today no row has a badge. A
missing key or a failed request shows no badge and never blocks the rows. Counts above 99 show as
99+, and the screen reader hears the real number ("My Orders, 3 new"). The header also shows the
joined month. Rows whose screens are not built answer with the "coming soon" message and are never
hidden; Sign Out is covered under Account Logout (US-104). Push-driven badge refresh is not built
yet (no push in the app), so badges refresh on visit and on pull down only.

## Profile Management (US-003)

Home's Profile tab opens `/profile` for signed-in users; guests are routed to Sign In.
The page follows the Figma Make `ProfileScreen`: a header (avatar, name with a verified mark,
masked mobile, rating, transactions, edit button), the plan badge or Upgrade to Premium
invite, the Listings/Sold/Reviews tiles, the Buying, Selling and Account menus, Sign Out and the
main navigation. Menu rows and Upgrade are not built yet and answer with a passing
"coming soon" message. Rating, transactions, listings, sold and plan come from
`profileSummaryProvider` (`lib/features/profile/data/mock_profile_summary.dart`), which returns the
mock values from Figma Make. Replace that provider with real data when the ratings, orders,
listing and subscription stories are built.

The edit button opens `/profile/details`, which reads `GET /users/me`, shows the server's masked
mobile/email and joined date, and keeps the verified Aadhaar name read-only. The profile has no
city, state, address, pincode or date of birth (design change 2026-10-15). Edit profile changes
only the name and avatar; `PATCH /users/me` sends only `displayName`.

Profile > Account has a "My Addresses" row that only shows the passing "coming soon" message for
now (US-113).

Change avatar reads `GET /avatars`, displays only the returned catalog IDs using the existing
bundled avatar renderer, and requires confirmation before `PUT /users/me/avatar`. A removed
avatar remains displayed until another is selected; a rejected selection preserves the current
avatar. Failed edits retain the draft, and leaving an edited profile asks before discarding changes.

The backend only validates the display name on `PATCH`. Ratings and viewing another user's
profile are deferred backend capabilities. Security settings are
covered under Account Security (US-105). The existing avatar illustrations are placeholders pending final artwork.
Backend profile PATCH validation also differs from registration for Unicode combining marks;
server rejections are displayed rather than treated as successful saves.

Verification: `flutter test test/features/profile/profile_test.dart` covers repository payloads,
navigation, retry, partial edits, avatar confirmation/rejection, accessibility and large-text layout.
For manual testing, use an existing authenticated account, open Profile, edit one field, save,
reopen and confirm persistence. Cancel a changed draft, try invalid names, and test avatars
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

Logout also clears the saved Home location and any unfinished sign-up state so the next person
on a shared device does not see them (`LogoutAction`). The "session expired" notice is
suppressed during a deliberate logout.

Verification: `flutter test test/features/profile/profile_test.dart
test/features/auth/data/auth_data_test.dart
test/features/auth/presentation/session_controller_test.dart test/core/network/api_client_test.dart`.
Manual: sign in, open Profile, Sign Out, confirm you land on Sign In and that reopening the
app stays signed out; with the backend stopped, repeat and check the "finish signing you out"
message, then restart the backend and the app and confirm the old token is rejected.

## Account Security (US-105)

Profile > Account > Account Security (`/profile/security`) shows, from
`GET /users/me/account-security` and `GET /users/me/sessions`:

- **Sign-in details:** the masked mobile number and email, each with a Change button, and the
  Aadhaar status (icon and words). When Aadhaar is not verified, "Verify now" opens the existing
  Aadhaar step, which active users may open later.
- **Active sessions:** up to 10 signed-in devices, most recent first, with the last active time,
  the IP address and a "This device" tag. "Log out of all other devices" asks first, then calls
  `POST /users/me/sessions/revoke-others`; it is hidden when this is the only device.
- **Delete My Account:** answers with the "coming soon" message until Sprint 14 (US-063/US-098).

Changing the mobile number or email (`/profile/security/mobile`, `/profile/security/email`) is
two steps on one page: enter the new value, then confirm the 6-digit code sent to it
(`.../change/initiate` and `.../change/verify`). The current value stays active on the server
until the code is confirmed, so leaving midway changes nothing. Resend follows the sign-up rules
(30 s cooldown, 3 sends); the backend also limits 3 sends and 5 wrong codes per 10 minutes per
value. `ContactChangeController` holds the state; the OTP boxes and the resend line are the same
widgets as the sign-up steps.

The app names itself in its `User-Agent` header (`JustQlic/0.1.0 (iOS)`), which the backend stores
as the session's device name. Sessions created before this (and tools such as Swagger) show the
header as sent, or "Unknown device" for the Dart default.

Known gaps and notes:

- The backend serialises the session flag as `current` (the testing guide and LLD say
  `isCurrent`); the app reads both.
- The old mobile number or email gets no alert about the change: that needs US-077.
- Revoked devices find out on their next request (401, then a failed refresh) and show the
  "session expired" notice.
- The Hindi strings need native-speaker review.

Verification: `flutter test test/features/account_security`. Manual: open Profile > Account
Security; change the number to an unused one with the code from the backend console; try a number
that belongs to another account, a wrong code and an expired code; sign in on a second device or
simulator, check both appear, then log out of other devices and confirm the second one is signed
out on its next action.

## Notifications (US-077)

The bell on Home and Profile > Account > Notifications open the notification history
(`/notifications`, signed-in users only). It reads `GET /notifications?page&size=20` (newest first;
the unread count comes in the `X-Unread-Notifications` response header) and shows:

- **Cards:** an icon, the title and text the backend sent, and how long ago. Unread ones have a
  tinted background, a bar on the left, a dot and are announced as "Unread". Tapping one marks it
  read (`PATCH /notifications/{id}/read`, undone if it fails) and opens its screen from `deepLink`:
  `/profile` switches to the Profile tab, `/profile/account-security` opens Account Security, any
  other link (for example `/support`) says "coming soon" until that screen exists.
- **Tabs:** All plus one tab per category that has notifications (Account, Orders, Messages,
  Listings, Others); the row is hidden when there is only one category. The category comes from the
  `eventType` prefix (`ACCOUNT_`/`AADHAAR_` account, `ORDER_`/`PAYMENT_`/`SHIPMENT_`/`REFUND_`... orders,
  `MESSAGE_`/`CHAT_`/`OFFER_` messages, `LISTING_` listings); anything unknown is Others. Tabs are
  worked out from the pages loaded so far.
- **Mark all read:** `PATCH /notifications/read-all`; shown only while something is unread.
- **Loading:** pull to refresh, the next page loads when the list nears its end (or does not fill
  the screen), with a retry line when a page fails.
- **Unread count:** `unreadNotificationsProvider` feeds the Home bell and the Profile row (the
  backend sends no `NOTIFICATIONS` badge). It is fetched with one `size=1` request and kept in step by
  the page, so returning to Home needs no second request.

Notification text is shown as the backend sends it (English). Push, notification preferences and
quiet hours are not built (US-087); the backend sends only account events today.

## Address entry and verification (US-108)

Design change 2026-10-15: Sign Up and Home no longer enter or verify an address. Sign Up collects
only the avatar, name, optional gender, terms and consent. The address search field, verification
status and state picker (`lib/features/address`) are kept for reuse when an address is saved at
checkout (US-020) and when posting an item (US-004); nothing saves an address yet.

The **Search your address** field starts after 3 characters and a 300 ms pause, lists up to 5
suggestions restricted to India, and picking one fills the fields below it, which stay editable.
The address, landmark, city, state and pincode are checked with `POST /addresses/verify` 700 ms
after the user stops editing, and the status shows under the address: checking, verified, refused
(with the reason) or "can't check right now". Editing a field drops the chosen place, so `placeId`
is sent only while the fields are exactly what the suggestion filled in.

- **Home location (US-111):** the location header opens a sheet with exactly two options, "Use my
  current location" and "Use my saved location". There is no address entry, Places search or
  verification on Home. "Use my saved location" opens a pop-up (`saved_location_dialog.dart`)
  listing the saved addresses (name and full address) from `GET /users/me/addresses`; picking one
  uses only its city, state and pincode to find listings near it. With no saved address the pop-up
  says an address is saved when the user buys or sells. The chosen place is kept on the device
  only, never saved as an address or sent to the server.
- **Search modes:** `ADDRESS_SEARCH=mock` (default; a small built-in list of Indian addresses, needs
  no key, rejected in prod) or `google` (Places API (New) called directly from the app; needs
  `GOOGLE_PLACES_API_KEY`). Restrict the key to the Places API and to the app: the app sends
  `X-Ios-Bundle-Identifier` on iOS and `X-Android-Package` plus `X-Android-Cert` (set
  `GOOGLE_PLACES_ANDROID_CERT` to the signing certificate SHA-1) on Android. With `google` the
  suggestion list shows "Powered by Google"; confirm the attribution rules before release.
- **Manual entry always works:** when the search fails or finds nothing the field says so and the
  form below is used as before.
- **Try it with the sandbox backend:** an address line containing `unverified` is refused, one
  containing `unavailable` simulates a provider outage, and a pincode that does not fit the state's
  postal zone is refused.

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
    profile/                # profile page, details, menu badges
    account_security/       # US-105: sign-in details, contact change, active sessions
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
