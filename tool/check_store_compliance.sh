#!/usr/bin/env bash
# Static pre-release checks for Google Play and App Store requirements.
# Default: findings are reported as warnings (exit 0). With --strict they fail the run.
# Only covers what can be verified from the repository; see docs/Store-Compliance.md
# for the manual checklist (store listings, data-safety/privacy forms, etc.).
set -uo pipefail
cd "$(dirname "$0")/.."

strict=0
[[ "${1:-}" == "--strict" ]] && strict=1

failures=0
pass() { echo "PASS  $1"; }
flag() {
  failures=$((failures + 1))
  echo "::warning title=Store compliance::$1"
  echo "FLAG  $1"
}

MANIFEST=android/app/src/main/AndroidManifest.xml
GRADLE=android/app/build.gradle.kts
PLIST=ios/Runner/Info.plist
PBX=ios/Runner.xcodeproj/project.pbxproj

echo "== Android =="

if grep -Eq 'signingConfig *= *signingConfigs\.getByName\("debug"\)' "$GRADLE"; then
  flag "Release build is signed with the debug key; Play requires a release upload key"
else
  pass "Release build does not use the debug signing config"
fi

if grep -Eq 'applicationId *= *"com\.example\.' "$GRADLE"; then
  flag "applicationId uses the com.example namespace"
else
  pass "applicationId is not com.example.*"
fi

if grep -q 'usesCleartextTraffic="true"' "$MANIFEST"; then
  flag "Manifest enables cleartext traffic"
else
  pass "Cleartext traffic is not enabled in the main manifest"
fi

if grep -q 'android:debuggable="true"' "$MANIFEST"; then
  flag "Manifest sets android:debuggable=true"
else
  pass "Manifest is not debuggable"
fi

allowed_permissions="INTERNET ACCESS_COARSE_LOCATION"
unexpected=""
for p in $(grep -o 'uses-permission android:name="[^"]*"' "$MANIFEST" | sed 's/.*"\(.*\)"/\1/'); do
  short="${p##*.}"
  [[ " $allowed_permissions " == *" $short "* ]] || unexpected="$unexpected $short"
done
if [[ -n "$unexpected" ]]; then
  flag "Permissions outside the approved list:$unexpected (needs Play declaration; update allowlist when approved)"
else
  pass "Android permissions match the approved list ($allowed_permissions)"
fi

echo "== iOS =="

if [[ -f ios/Runner/PrivacyInfo.xcprivacy ]]; then
  pass "PrivacyInfo.xcprivacy present"
else
  flag "ios/Runner/PrivacyInfo.xcprivacy missing (required privacy manifest for uploads)"
fi

if grep -q 'ITSAppUsesNonExemptEncryption' "$PLIST"; then
  pass "ITSAppUsesNonExemptEncryption declared"
else
  flag "ITSAppUsesNonExemptEncryption not declared in Info.plist (export-compliance prompt on every upload)"
fi

# plugin dependency (imported in lib/) -> required Info.plist usage description
check_usage() {
  local plugin="$1" key="$2" import="$3"
  if grep -Eq "^  ${plugin}:" pubspec.yaml && grep -rqE "package:${import}" lib; then
    if grep -q "$key" "$PLIST"; then
      pass "$key present ($plugin)"
    else
      flag "$key missing in Info.plist but $plugin is used"
    fi
  fi
}
check_usage geolocator_apple NSLocationWhenInUseUsageDescription geolocator_
check_usage image_picker NSPhotoLibraryUsageDescription image_picker
check_usage image_picker NSCameraUsageDescription image_picker
check_usage local_auth NSFaceIDUsageDescription local_auth

if grep -Eq 'PRODUCT_BUNDLE_IDENTIFIER = com\.example\.' "$PBX"; then
  flag "iOS bundle identifier uses the com.example namespace"
else
  pass "iOS bundle identifier is not com.example.*"
fi

echo "== Config =="

for f in config/staging.json config/prod.json; do
  if grep -Eq '"http://' "$f"; then
    flag "$f contains a cleartext http:// URL"
  else
    pass "$f has no cleartext URLs"
  fi
done

if grep -q 'api.example.invalid' config/prod.json; then
  flag "config/prod.json still has the placeholder API host"
else
  pass "config/prod.json has a real API host"
fi

echo
echo "$failures finding(s)."
if [[ $strict -eq 1 && $failures -gt 0 ]]; then
  exit 1
fi
exit 0
