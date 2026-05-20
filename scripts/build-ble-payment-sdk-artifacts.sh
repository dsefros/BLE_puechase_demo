#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ios_sdk="$repo_root/kit/ios/BlePaymentKit"
android_sdk="$repo_root/kit/android/ble-payment-kit"
android_integration_kit="$repo_root/kit/android/ble-payment-integration-kit"
ios_integration_kit="$repo_root/kit/ios/ble-payment-ios-integration-kit"
shared_test_vectors="$repo_root/kit/docs/test-vectors"
docs_dir="$repo_root/kit/docs"
dist_dir="$repo_root/dist/ble-payment-sdk"

for path in "$ios_sdk" "$android_sdk" "$android_integration_kit" "$ios_integration_kit" "$shared_test_vectors" "$docs_dir"; do
  if [[ ! -d "$path" ]]; then
    echo "Missing required SDK handoff path: $path" >&2
    exit 1
  fi
done

swift test --package-path "$ios_sdk"

rm -rf "$dist_dir"
mkdir -p "$dist_dir"

ios_stage="$(mktemp -d)"
android_stage=""
trap 'rm -rf "$android_stage" "$ios_stage"' EXIT

cp "$ios_integration_kit/archive-root-README.md" "$ios_stage/README.md"
cp -R "$ios_sdk" "$ios_stage/BlePaymentKit"
cp -R "$ios_integration_kit" "$ios_stage/ble-payment-ios-integration-kit"
rm -f "$ios_stage/ble-payment-ios-integration-kit/archive-root-README.md"
mkdir -p "$ios_stage/ble-payment-ios-integration-kit/test-vectors"
cp "$shared_test_vectors"/*.json "$ios_stage/ble-payment-ios-integration-kit/test-vectors/"
rm -rf "$ios_stage/BlePaymentKit/.build" "$ios_stage/BlePaymentKit/.swiftpm"
find "$ios_stage" -name ".DS_Store" -delete

(
  cd "$ios_stage"
  zip -qr "$dist_dir/BlePaymentKit-ios-spm.zip" README.md BlePaymentKit ble-payment-ios-integration-kit -x '*/.DS_Store'
)

required_ios_entries=(
  "README.md"
  "BlePaymentKit/Package.swift"
  "BlePaymentKit/Sources/"
  "ble-payment-ios-integration-kit/README.md"
  "ble-payment-ios-integration-kit/docs/overview.md"
  "ble-payment-ios-integration-kit/docs/quick-start.md"
  "ble-payment-ios-integration-kit/docs/scan-result-to-sdk-input.md"
  "ble-payment-ios-integration-kit/docs/sdk-api-contract.md"
  "ble-payment-ios-integration-kit/docs/packet-format.md"
  "ble-payment-ios-integration-kit/docs/ios-corebluetooth-scanning.md"
  "ble-payment-ios-integration-kit/reference/"
  "ble-payment-ios-integration-kit/examples/"
  "ble-payment-ios-integration-kit/test-vectors/valid-packet.json"
)

ios_archive_listing="$(zipinfo -1 "$dist_dir/BlePaymentKit-ios-spm.zip")"
for required in "${required_ios_entries[@]}"; do
  if ! grep -Fxq "$required" <<<"$ios_archive_listing"; then
    echo "Missing required iOS integration kit entry in archive: $required" >&2
    exit 1
  fi
done

android_stage="$(mktemp -d)"

cp "$android_integration_kit/archive-root-README.md" "$android_stage/README.md"
cp -R "$android_sdk" "$android_stage/ble-payment-kit"
cp -R "$android_integration_kit" "$android_stage/ble-payment-integration-kit"
rm -f "$android_stage/ble-payment-integration-kit/archive-root-README.md"
mkdir -p "$android_stage/ble-payment-integration-kit/test-vectors"
cp "$shared_test_vectors"/*.json "$android_stage/ble-payment-integration-kit/test-vectors/"
rm -rf "$android_stage/ble-payment-kit/build" "$android_stage/ble-payment-kit/.gradle"

(
  cd "$android_stage"
  zip -qr "$dist_dir/ble-payment-kit-android-source.zip" \
    README.md \
    ble-payment-kit \
    ble-payment-integration-kit \
    -x '*/.DS_Store'
)

required_android_entries=(
  "README.md"
  "ble-payment-kit/src/main/kotlin/ru/paymentguide/blepaymentkit/BlePaymentKit.kt"
  "ble-payment-integration-kit/docs/overview.md"
  "ble-payment-integration-kit/docs/quick-start.md"
  "ble-payment-integration-kit/docs/scan-result-to-sdk-input.md"
  "ble-payment-integration-kit/docs/sdk-api-contract.md"
  "ble-payment-integration-kit/docs/packet-format.md"
  "ble-payment-integration-kit/reference/src/main/kotlin/ru/paymentguide/blepaymentkit/integration/BlePaymentScanMapper.kt"
  "ble-payment-integration-kit/reference/src/main/kotlin/ru/paymentguide/blepaymentkit/integration/BlePaymentScanner.kt"
  "ble-payment-integration-kit/examples/minimal-sdk-usage.kt"
  "ble-payment-integration-kit/test-vectors/valid-packet.json"
)

archive_listing="$(zipinfo -1 "$dist_dir/ble-payment-kit-android-source.zip")"
for required in "${required_android_entries[@]}"; do
  if ! grep -Fxq "$required" <<<"$archive_listing"; then
    echo "Missing required Android integration kit entry in archive: $required" >&2
    exit 1
  fi
done

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
