# BLE Payment SDK Handoff Kit

This `kit/` directory is the standalone BLE Payment SDK handoff package for external developers. It is intentionally separate from the demo applications and contains only SDK source, shared contract documentation, test vectors, and artifact packaging support.

## Contents

- iOS SDK: [`kit/ios/BlePaymentKit`](../kit/ios/BlePaymentKit)
- Android SDK: [`kit/android/ble-payment-kit`](../kit/android/ble-payment-kit)
- SDK docs: [`kit/docs`](../kit/docs)
- Shared contract: [`kit/docs/ble-payment-sdk-contract.md`](../kit/docs/ble-payment-sdk-contract.md)
- Handoff notes: [`kit/docs/ble-payment-sdk-handoff.md`](../kit/docs/ble-payment-sdk-handoff.md)
- Artifact manifest: [`kit/docs/ble-payment-sdk-artifact-manifest.md`](../kit/docs/ble-payment-sdk-artifact-manifest.md)
- Shared test vectors: [`kit/docs/test-vectors`](../kit/docs/test-vectors)

## Build distributable artifacts

Run the artifact builder from the repository root:

```bash
bash scripts/build-ble-payment-sdk-artifacts.sh
```

The script packages the standalone iOS SDK, standalone Android SDK, and SDK docs into `dist/ble-payment-sdk/`, then writes `SHA256SUMS.txt` for handoff verification. The generated `dist/` directory is ignored by Git and should not be committed.
