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
candidates = [d for runtime, items in devices.items() if 'iOS-27' in runtime for d in items if d.get('isAvailable') and d['name'] == 'iPhone 17']
if not candidates:
    raise SystemExit('No installed iPhone 17 / iOS 27 simulator')
print(candidates[0]['udid'])
PY
)
trap 'xcrun simctl shutdown "$UDID" || true' EXIT
xcrun simctl boot "$UDID" || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl status_bar "$UDID" override --time '9:41' --dataNetwork wifi --wifiMode active --wifiBars 3 --batteryState charged --batteryLevel 100
APP=$(find build/Build/Products/Debug-iphonesimulator -maxdepth 1 -name '*.app' ! -name '*Tests*' | head -n 1)
xcrun simctl install "$UDID" "$APP"
for appearance in light dark; do
  xcrun simctl ui "$UDID" appearance "$appearance"
  for page in today plaza messages profile schedule login; do
    xcrun simctl terminate "$UDID" com.nigo.nest || true
    xcrun simctl launch "$UDID" com.nigo.nest -preview "$page" -AppleLanguages '(zh-Hans)' -AppleLocale zh_CN
    sleep 4
    xcrun simctl io "$UDID" screenshot "screenshots/${page}-${appearance}.png"
  done
done
xcrun simctl ui "$UDID" appearance light
xcrun simctl ui "$UDID" content_size accessibility-extra-extra-extra-large
xcrun simctl terminate "$UDID" com.nigo.nest || true
xcrun simctl launch "$UDID" com.nigo.nest -preview today -AppleLanguages '(zh-Hans)'
sleep 4
xcrun simctl io "$UDID" screenshot screenshots/today-accessibility.png
printf '\nSource: compiled production SwiftUI views; local demonstration data.\nDevice: iPhone 17 SIMULATOR, not a physical iPhone.\n' >> screenshots/environment.txt
