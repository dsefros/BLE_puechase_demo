# BlePaymentKit iOS

Standalone Swift Package for deterministic BLE payment packet processing. The package does not scan for BLE devices, request permissions, render UI, submit payments, call backends, poll payment status, or integrate with an app.

## Location

The package lives at:

```text
kit/ios/BlePaymentKit
```

## Validation

Run iOS package tests from the repository root with:

```bash
swift test --package-path kit/ios/BlePaymentKit
```

The tests load shared JSON vectors from `kit/docs/test-vectors`.
