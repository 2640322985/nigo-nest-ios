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
    xcrun simctl launch --terminate-running-process "$UDID" com.nigo.nest -preview "$page" -previewAppearance "$appearance" -AppleLanguages '(zh-Hans)' -AppleLocale zh_CN
    sleep 4
    xcrun simctl io "$UDID" screenshot "screenshots/${page}-${appearance}.png"
  done
done
printf '\nSource: OS screenshots of compiled production SwiftUI views with local demonstration data.\nDevice: iPhone 17 / iOS 27.0 SIMULATOR, not a physical iPhone.\n' >> screenshots/environment.txt
