#!/bin/bash
set -euo pipefail
mkdir -p screenshots
xcodebuild -version > screenshots/environment.txt
xcrun simctl list runtimes >> screenshots/environment.txt
UDID=$(xcrun simctl create nigo-preview 'iPhone 17' com.apple.CoreSimulator.SimRuntime.iOS-27-0)
xcrun simctl boot "$UDID"
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
xcrun simctl shutdown "$UDID"
