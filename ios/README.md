# iOS BLEApp Skeleton

## Open in Xcode

1. Open `ios/BLEApp/BLEApp.xcodeproj` in Xcode.
2. Select the `BLEApp` scheme.
3. Build or run on an iOS Simulator.

## Current MVP scope

- Foreground-only, scan-only parity target with Android.
- PR 2 adds Volna BLE parser/filter parity (service-data parsing, manufacturer parsing, QRC conversion, RSSI filtering, candidate assembly) with hardware-independent unit tests.
- Shared BLE constants and behavior contract source of truth: `docs/ble-protocol-contract.md`.

## What this PR intentionally does NOT implement

- GATT read/write/notify.
- Background BLE modes.
- Backend/payment submission and final payment confirmation flow.

## Device testing note

Real BLE end-to-end validation still requires a physical iPhone and real BLE tag/terminal. Parser/filter logic is unit-tested and does not require BLE hardware.

## Local validation

Run from repository root:

- `xcodebuild -list -project ios/BLEApp/BLEApp.xcodeproj`
- `xcodebuild -project ios/BLEApp/BLEApp.xcodeproj -scheme BLEApp -destination 'platform=iOS Simulator,name=iPhone 17' build`
- `xcodebuild -project ios/BLEApp/BLEApp.xcodeproj -scheme BLEApp -destination 'platform=iOS Simulator,name=iPhone 17' test`

Simulator device name may need adjustment to match installed Xcode simulator runtimes.
