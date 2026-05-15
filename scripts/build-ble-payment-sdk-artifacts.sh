#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ios_sdk="$repo_root/kit/ios/BlePaymentKit"
android_sdk="$repo_root/kit/android/ble-payment-kit"
docs_dir="$repo_root/kit/docs"
dist_dir="$repo_root/dist/ble-payment-sdk"

for path in "$ios_sdk" "$android_sdk" "$docs_dir"; do
  if [[ ! -d "$path" ]]; then
    echo "Missing required SDK handoff path: $path" >&2
    exit 1
  fi
done

swift test --package-path "$ios_sdk"

rm -rf "$dist_dir"
mkdir -p "$dist_dir"

(
  cd "$repo_root/kit/ios"
  zip -qr "$dist_dir/BlePaymentKit-ios-spm.zip" BlePaymentKit \
    -x 'BlePaymentKit/.build/*' \
    -x 'BlePaymentKit/.swiftpm/*' \
    -x '*/.DS_Store'
)

(
  cd "$repo_root/kit/android"
  zip -qr "$dist_dir/ble-payment-kit-android-source.zip" ble-payment-kit \
    -x 'ble-payment-kit/build/*' \
    -x 'ble-payment-kit/.gradle/*' \
    -x '*/.DS_Store'
)

(
  cd "$repo_root/kit"
  zip -qr "$dist_dir/ble-payment-sdk-docs.zip" docs \
    -x '*/.DS_Store'
)

(
  cd "$dist_dir"
  sha256sum \
    BlePaymentKit-ios-spm.zip \
    ble-payment-kit-android-source.zip \
    ble-payment-sdk-docs.zip > SHA256SUMS.txt
)

echo "Built BLE Payment SDK artifacts in $dist_dir"
