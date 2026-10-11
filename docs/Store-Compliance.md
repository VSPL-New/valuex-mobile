# Store Compliance Checklist

Automated part: `tool/check_store_compliance.sh` (runs in CI as warnings; `--strict` or the
`strict_store_checks` workflow input fails on any finding). Everything else below is manual.

## Automated (static)

| Check | Platform |
| --- | --- |
| Release build not signed with debug key | Android |
| `applicationId` / bundle id not `com.example.*` | Both |
| No cleartext traffic, not debuggable | Android |
| Permissions limited to approved list (`INTERNET`, `ACCESS_COARSE_LOCATION`) | Android |
| `PrivacyInfo.xcprivacy` present | iOS |
| `ITSAppUsesNonExemptEncryption` declared | iOS |
| Usage-description strings for permission plugins in use | iOS |
| No `http://` or placeholder host in staging/prod config | Both |

## Manual: Google Play

- Target API level meets the current Play requirement (check at release time; Flutter's default is used).
- Upload an Android App Bundle (`flutter build appbundle`), enrol in Play App Signing, create a release upload key.
- Data safety form matches actual collection (phone, email, name, approximate location, Aadhaar-related data, identifiers).
- Public privacy policy URL, also linked in-app.
- Location permission justification (approximate location only).
- Account deletion: in-app path and a web URL declared in Play Console.
- Content rating questionnaire; UGC policy (report/block/moderation) for marketplace listings.
- Financial/payments declarations if escrow or payments ship.
- Indian DPDP Act: consent, purpose limitation and retention for Aadhaar and other sensitive data.

## Manual: Apple App Store

- App Privacy labels match `PrivacyInfo.xcprivacy` and third-party SDK manifests.
- Build with the Xcode/SDK version Apple currently requires.
- 4.8 Login Services: with Google sign-in offered, an equivalent privacy-preserving login (Sign in with Apple, or phone OTP meeting 4.8 criteria) is needed; confirm before submission.
- 5.1.1(v) In-app account deletion.
- 1.2 User-generated content: report, block, moderation contact.
- Review notes with a demo account (OTP login needs a fixed test number/OTP for reviewers).
- Export compliance answers (standard HTTPS only is exempt).

## Known gaps (at time of writing)

- Release build uses debug signing.
- `ios/Runner/PrivacyInfo.xcprivacy` missing; `ITSAppUsesNonExemptEncryption` not set.
- `config/prod.json` still has a placeholder API host.
- Logout and account deletion UI not yet built (US-104 mobile, US-063/098).
- Google sign-in runs on a mock verifier until real OAuth clients exist: create the Web, Android (SHA-1s) and iOS clients, set `GOOGLE_SERVER_CLIENT_ID`/`GOOGLE_IOS_CLIENT_ID` in `config/prod.json` and add the reversed iOS client ID URL scheme to `Info.plist` (the script flags all three).
- App Store 4.8: Google sign-in is now offered on iOS with no Sign in with Apple, so the equivalent-login decision is a release blocker for iOS.
- Play Data safety and Apple privacy labels must now list the Google account email collected at sign-in.
