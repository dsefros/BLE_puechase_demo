# Android BLE Payment Integration Kit

This bundle is the Android starter package for integrating BLE payment packet scanning into an existing Android app.

It includes:
- the Kotlin packet-processing SDK source (`../ble-payment-kit`),
- integration documentation (`docs/`),
- Android scanner/mapper reference source (`reference/`),
- usage snippets (`examples/`),
- JSON test vectors (`test-vectors/`).

## What this kit solves

It gives Android teams a deterministic packet-processing core (`BlePaymentKit`) and a practical mapping path from Android `ScanResult` into `BlePacketInput`.

## What it does not do

The SDK and reference layer do **not** provide permission UX, BLE enable prompts, app UI, payment confirmation/submission, backend calls, or navigation.

## Start here

1. [`docs/overview.md`](docs/overview.md)
2. [`docs/quick-start.md`](docs/quick-start.md)
3. [`docs/scan-result-to-sdk-input.md`](docs/scan-result-to-sdk-input.md)
4. [`docs/sdk-api-contract.md`](docs/sdk-api-contract.md)
5. [`docs/packet-format.md`](docs/packet-format.md)

## Fast path

1. Copy or include `ble-payment-kit` in your project.
2. Instantiate `BlePaymentKit(BlePaymentConfig.default())`.
3. Use `reference/` mapper logic (or adapt it) to map `ScanResult` -> `BlePacketInput`.
4. Call `sdk.process(input)` and handle `Accepted` / `Rejected`.
5. Stop or continue scanning per your app flow.

> The `reference/` integration source is intentionally a starting point, not a mandatory framework.
