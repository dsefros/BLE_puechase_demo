# Android BLE Payment Integration Kit

This archive is the external handoff package for Android teams integrating BLE payment packet scanning.

## Included folders

- `ble-payment-kit/` — Kotlin packet-processing SDK source (deterministic parsing/validation/candidate creation).
- `ble-payment-integration-kit/docs/` — integration guide and API/packet contract docs.
- `ble-payment-integration-kit/reference/` — reference Android scanner/mapper layer (`ScanResult` -> `BlePacketInput`).
- `ble-payment-integration-kit/examples/` — copy/paste oriented integration snippets.
- `ble-payment-integration-kit/test-vectors/` — JSON vectors packaged from shared source `kit/docs/test-vectors`.

## Responsibility split

- **SDK**: packet parsing/validation and accepted candidate creation only.
- **Reference integration layer**: Android BLE scan callback mapping into SDK input.
- **Host app**: permissions UX, Bluetooth readiness UX, UI, payment confirmation/submission, backend calls.

## Fast path

1. Include `ble-payment-kit` source in your Android project.
2. Read `ble-payment-integration-kit/docs/quick-start.md`.
3. Wire `BlePaymentScanMapper` + `BlePaymentScanner` (or adapt them) to your `BluetoothLeScanner` callback.
4. Process mapped inputs via `BlePaymentKit.process(...)`.
5. On `Accepted`, transition to your app payment flow and stop/continue scanning per your policy.

## Start here

- `ble-payment-integration-kit/docs/overview.md`
- `ble-payment-integration-kit/docs/quick-start.md`
- `ble-payment-integration-kit/docs/scan-result-to-sdk-input.md`
- `ble-payment-integration-kit/docs/sdk-api-contract.md`
- `ble-payment-integration-kit/docs/packet-format.md`
