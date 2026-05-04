# iOS BLEApp Skeleton

## Open in Xcode

1. Open `ios/BLEApp/BLEApp.xcodeproj` in Xcode.
2. Select the `BLEApp` scheme.
3. Build or run on an iOS Simulator.

## Current MVP scope

- Foreground-only, scan-only parity target with Android.
- Shared BLE constants and behavior contract source of truth: `docs/ble-protocol-contract.md`.

## What this PR intentionally does NOT implement

- Real BLE scanning (CoreBluetooth runtime scan) is not implemented yet.
- Background BLE modes are out of current MVP scope.
- GATT read/write/notify is out of current MVP scope.

## Device testing note

Real BLE validation in later PRs should use a physical iPhone because simulator BLE behavior is limited.

## Architecture mapping

- Android `presentation/` → iOS `UI/` + app state placeholders.
- Android `domain/` → iOS `Domain/` placeholders.
- Android `data/ble/` → iOS `BLE/` placeholders.
- Android `platform/` → iOS `Infrastructure/Prerequisites/` placeholders.
- Android `app/di/` → iOS `App/` composition placeholders.


## Local validation

Run from repository root:

- `xcodebuild -list -project ios/BLEApp/BLEApp.xcodeproj`
- `xcodebuild -project ios/BLEApp/BLEApp.xcodeproj -scheme BLEApp -destination 'platform=iOS Simulator,name=iPhone 16' build`
- `xcodebuild -project ios/BLEApp/BLEApp.xcodeproj -scheme BLEApp -destination 'platform=iOS Simulator,name=iPhone 16' test`

Simulator device name may need adjustment to match your installed Xcode simulator runtimes.
