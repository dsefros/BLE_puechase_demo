# iOS BLEApp Skeleton

## Open in Xcode

1. Open `ios/BLEApp/BLEApp.xcodeproj` in Xcode.
2. Select the `BLEApp` scheme.
3. Build or run on an iOS Simulator.

## Current MVP scope

- Foreground-only, scan-only parity target with Android.
- PR 2 added Volna BLE parser/filter parity (service-data parsing, manufacturer parsing, QRC conversion, RSSI filtering, candidate assembly) with hardware-independent unit tests.
- PR 3 adds the first iOS confirmation flow: scan -> parsed `PaymentCandidate` -> ready to confirm -> deterministic placeholder submit -> success/error.
- This PR adds iOS-only Home screen visual parity and DEBUG-only simulator demo states for payment-flow UI validation.
- Shared BLE constants and behavior contract source of truth: `docs/ble-protocol-contract.md`.

## Supported payment flow (PR 3 + visual parity pass)

- Home state transitions: `idle`, `scanning`, `readyForConfirmation(candidate)`, `submittingPayment(candidate)`, `paymentSuccess(candidate)`, `paymentError(candidate,message)`, `scannerUnavailable`, and `blockingError`.
- When a valid candidate is parsed, scanning is stopped and the confirmation UI is shown.
- Confirmation UI includes merchant, formatted amount, QRC ID, and RSSI diagnostics (`rssi`, `finalRSSI`, `rssiDelta`).
- "Confirm payment" uses an in-app deterministic placeholder submit path only (no real backend).

## Simulator validation via DEBUG demo scenarios

On iOS Simulator, CoreBluetooth is typically unsupported, so only unsupported scanner state appears in live mode.

To validate UI states in Simulator:

1. Run a **DEBUG** build in Xcode.
2. Open Home screen.
3. Use the **Demo scenario (DEBUG)** segmented control.
4. Keep `Live` selected for real runtime behavior.
5. Switch to preview scenarios to validate UI states without BLE hardware:
   - `Unsupported`
   - `Ready`
   - `Scanning`
   - `Candidate`
   - `Submitting`
   - `Success`
   - `Error`

Notes:
- Demo scenarios are DEBUG-only and are not shipped in release builds.
- Non-live scenarios are preview-only and intentionally do not trigger real scanner actions.
- Live mode preserves the real injected scanner/parser/payment behavior from `AppContainer`.


## iOS migration step: payment UX + scanner UX + submission boundary

This iOS update includes:
- product-grade Home payment UI restructuring (payment flow first, diagnostics second),
- user-facing Bluetooth/scanner status messaging,
- payment submission boundary behind `PaymentSubmissionServiceProtocol`.

Current payment submission remains placeholder-only (`PlaceholderPaymentSubmissionService`); no real backend/payment API is implemented.

## Validation scope

- Hardware-independent unit tests cover scanner status mapping and payment submission success/failure transitions.
- Real BLE runtime validation still requires a physical iPhone and real BLE tag/terminal.
- Simulator is useful for UI behavior and tests, but not full BLE runtime behavior.

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
- `rg -n "connect|discoverServices|readValue|writeValue|setNotifyValue|UIBackgroundModes|bluetooth-central" ios/BLEApp/BLEApp ios/README.md`

Simulator device name may need adjustment to match installed Xcode simulator runtimes.
