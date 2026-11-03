#!/bin/bash
set -euxo pipefail
mkdir -p screenshots
xcodebuild -version > screenshots/environment.txt
xcrun simctl list runtimes >> screenshots/environment.txt
xcrun simctl list devices available --json > screenshots/devices.json
UDID=$(python3 - <<'PY'
import json
with open('screenshots/devices.json') as f:
    devices = json.load(f)['devices']
candidates = [d for runtime, items in devices.items() if 'iOS-27-0' in runtime for d in items if d.get('isAvailable') and d['name'] == 'iPhone 17']
if not candidates:
    raise SystemExit('No installed iPhone 17 / iOS 27 simulator')
print(candidates[0]['udid'])
PY
)
trap 'xcrun simctl shutdown "$UDID" || true' EXIT
xcrun simctl boot "$UDID" || true
xcrun simctl bootstatus "$UDID" -b
APP=$(find build/Build/Products/Debug-iphonesimulator -maxdepth 1 -name '*.app' ! -name '*Tests*' | head -n 1)
xcrun simctl install "$UDID" "$APP"
for appearance in light dark; do
  for page in today plaza profile; do
    if [ "$appearance-$page" = light-today ]; then
      xcrun simctl launch --terminate-running-process "$UDID" com.nigo.nest -preview "$page" -previewAppearance "$appearance" -persistTheme journal -AppleLanguages '(zh-Hans)' -AppleLocale zh_CN
    else
      xcrun simctl launch --terminate-running-process "$UDID" com.nigo.nest -preview "$page" -previewAppearance "$appearance" -AppleLanguages '(zh-Hans)' -AppleLocale zh_CN
    fi
    sleep 10
    SHOT="screenshots/journal-${page}-${appearance}.png"
    for attempt in 1 2 3; do
      xcrun simctl io "$UDID" screenshot "$SHOT"
      if swift scripts/check-screenshot.swift "$SHOT"; then break; fi
      if [ "$attempt" = 3 ]; then exit 1; fi
      sleep 10
    done
  done
done
xcrun simctl launch --terminate-running-process "$UDID" com.nigo.nest -preview themes -previewAppearance light -AppleLanguages '(zh-Hans)' -AppleLocale zh_CN
sleep 10
xcrun simctl io "$UDID" screenshot screenshots/journal-theme-picker.png
swift scripts/check-screenshot.swift screenshots/journal-theme-picker.png
xcrun simctl launch --terminate-running-process "$UDID" com.nigo.nest -preview today -previewTheme monochrome -previewAppearance light -AppleLanguages '(zh-Hans)' -AppleLocale zh_CN
sleep 10
xcrun simctl io "$UDID" screenshot screenshots/monochrome-today-light.png
swift scripts/check-screenshot.swift screenshots/monochrome-today-light.png
xcrun simctl launch --terminate-running-process "$UDID" com.nigo.nest -AppleLanguages '(zh-Hans)' -AppleLocale zh_CN
sleep 10
xcrun simctl io "$UDID" screenshot screenshots/production-login.png
swift scripts/check-screenshot.swift screenshots/production-login.png
printf '\nSource: OS screenshots of compiled production SwiftUI views with local demonstration data.\nDevice: iPhone 17 / iOS 27.0 SIMULATOR, not a physical iPhone.\n' >> screenshots/environment.txt
