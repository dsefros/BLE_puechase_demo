# iOS BLEApp Skeleton

## Open in Xcode

1. Open `ios/BLEApp/BLEApp.xcodeproj` in Xcode.
2. Select the `BLEApp` scheme.
3. Build or run on an iOS Simulator.

## Current MVP scope

- Foreground-only, scan-only parity target with Android.
- PR 2 added Volna BLE parser/filter parity (service-data parsing, manufacturer parsing, QRC conversion, RSSI filtering, candidate assembly) with hardware-independent unit tests.
- PR 3 adds the first iOS confirmation flow: scan -> parsed `PaymentCandidate` -> ready to confirm -> deterministic placeholder submit -> success/error.
- Shared BLE constants and behavior contract source of truth: `docs/ble-protocol-contract.md`.

## Supported payment flow (PR 3)

- Home state transitions: `idle`, `scanning`, `readyForConfirmation(candidate)`, `submittingPayment(candidate)`, `paymentSuccess(candidate)`, `paymentError(candidate,message)`, `scannerUnavailable`, and `blockingError`.
- When a valid candidate is parsed, scanning is stopped and the confirmation UI is shown.
- Confirmation UI includes merchant, formatted amount, QRC ID, and RSSI diagnostics (`rssi`, `finalRSSI`, `rssiDelta`).
- "Confirm payment" uses an in-app deterministic placeholder submit path only (no real backend).

## Non-goals (still intentionally not implemented)

- No real backend/payment submission.
- No GATT read/write/notify.
- No background BLE modes.
- No Android app changes in this iOS PR.

## Device testing note

Real BLE end-to-end validation still requires a physical iPhone and real BLE tag/terminal. Parser/filter and payment-flow transitions are unit-tested and do not require BLE hardware.

## Local validation

Run from repository root:

- `xcodebuild -list -project ios/BLEApp/BLEApp.xcodeproj`
- `xcodebuild -project ios/BLEApp/BLEApp.xcodeproj -scheme BLEApp -destination 'platform=iOS Simulator,name=iPhone 17' build`
- `xcodebuild -project ios/BLEApp/BLEApp.xcodeproj -scheme BLEApp -destination 'platform=iOS Simulator,name=iPhone 17' test`

Simulator device name may need adjustment to match installed Xcode simulator runtimes.
