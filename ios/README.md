# iOS BLEApp Skeleton

## Open in Xcode

1. Open `ios/BLEApp/BLEApp.xcodeproj` in Xcode.
2. Select the `BLEApp` scheme.
3. Build or run on an iOS Simulator.

## Current MVP scope

- Foreground-only, scan-only parity target with Android.
- PR 2 added Volna BLE parser/filter parity (service-data parsing, manufacturer parsing, QRC conversion, RSSI filtering, candidate assembly) with hardware-independent unit tests.
- PR 3 adds the first iOS confirmation flow: scan -> parsed `PaymentCandidate` -> ready to confirm -> deterministic placeholder submit -> success/error.
- The latest iOS-only Home visual pass reuses the Android Lottie assets through the official `lottie-ios` Swift Package to bring the iOS payment flow closer to Android while preserving the existing scan/payment state machine.
- Shared BLE constants and behavior contract source of truth: `docs/ble-protocol-contract.md`.

## Android Lottie visual parity

The iOS app owns copies of the Android Lottie JSON files under `ios/BLEApp/BLEApp/Resources/Lottie/`. They are included in the `BLEApp` target resources and loaded by a SwiftUI wrapper around `LottieAnimationView`.

State-to-animation mapping:

- `background.json` -> app background, cropped/fill and looped behind the light Home UI.
- `bluetooth.json` -> idle/welcome scan hero. The central Bluetooth hero remains the scan trigger.
- `loader.json` -> scanning and submitting-payment wait states, looped.
- `store_animated.json` -> payment confirmation store visual.
- `success.json` -> payment-success result visual, played once.
- `failed.json` -> payment-error result visual, played once.

If a Lottie animation cannot be loaded, iOS falls back to the existing SwiftUI-coded visuals so the payment flow remains usable.

## Supported payment flow (PR 3 + visual parity pass)

- Home state transitions: `idle`, `scanning`, `readyForConfirmation(candidate)`, `submittingPayment(candidate)`, `paymentSuccess(candidate)`, `paymentError(candidate,message)`, `scannerUnavailable`, and `blockingError`.
- When a valid candidate is parsed, scanning is stopped and the confirmation UI is shown.
- Confirmation UI includes merchant and formatted amount, with QRC ID retained in DEBUG diagnostics/secondary debug text.
- "Confirm payment" uses an in-app deterministic placeholder submit path only (no real backend).
- The idle Home scan trigger is the central Bluetooth hero; there is no separate bottom start-scan button.

## Simulator validation via DEBUG Android-like light full-screen demo scenarios

On iOS Simulator, CoreBluetooth is typically unsupported, so only unsupported scanner state appears in live mode.

To validate UI states in Simulator:

1. Run a **DEBUG** build in Xcode.
2. Open Home screen.
3. Use the **Demo scenario (DEBUG)** segmented control.
4. Keep `Live` selected for real runtime behavior.
5. Switch to preview scenarios to validate Android-like light full-screen UI states without BLE hardware. Demo screens also support preview-safe UI actions: tapping the Bluetooth hero in `Ready` moves to `Scanning`, `Cancel` returns to `Ready`, confirmation moves to `Submitting`, and success/error actions return to `Ready` without invoking the real scanner or payment methods.
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
- payment submission boundary behind `PaymentSubmissionServiceProtocol`,
- Android Lottie asset reuse for Home payment visual parity.

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

Simulator device name may need adjustment to match installed Xcode simulator runtimes.
