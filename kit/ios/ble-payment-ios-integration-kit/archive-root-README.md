# iOS BLE Payment Integration Kit Archive

This archive packages everything needed to integrate BLE payment packet processing on iOS.

## Archive layout

- `BlePaymentKit/` — Swift Package with deterministic packet parsing/validation and candidate creation.
- `ble-payment-ios-integration-kit/docs/` — iOS integration guide.
- `ble-payment-ios-integration-kit/reference/` — CoreBluetooth scanner/mapper reference source.
- `ble-payment-ios-integration-kit/examples/` — practical usage snippets.
- `ble-payment-ios-integration-kit/test-vectors/` — shared JSON test vectors.

## Fast path

1. Add `BlePaymentKit/` as a local Swift Package dependency.
2. Follow `ble-payment-ios-integration-kit/docs/quick-start.md`.
3. Use `ble-payment-ios-integration-kit/docs/scan-result-to-sdk-input.md` to map CoreBluetooth `advertisementData` into `BlePacketInput`.
