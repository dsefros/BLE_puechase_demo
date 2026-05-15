# BLE Payment SDK Handoff

The standalone BLE Payment SDK handoff is rooted at `kit/` and can be shared as one package with external developers.

## Package structure

- `kit/ios/BlePaymentKit` — standalone Swift Package for iOS/macOS packet processing.
- `kit/android/ble-payment-kit` — standalone Kotlin/JVM library skeleton for Android-compatible packet processing.
- `kit/docs/ble-payment-sdk-contract.md` — shared packet-processing API and behavior contract.
- `kit/docs/test-vectors` — shared JSON test vectors used to validate both SDK implementations.

## Boundaries

The SDKs are intentionally standalone. They do not include BLE scanning lifecycle management, permission prompts, UI, payment submission, backend networking, polling, navigation, analytics, or demo-app logging.

Do not integrate these SDKs into the demo app as part of the handoff package. Application folders remain separate from `kit/`.

## Artifact build

From the repository root, run:

```bash
bash scripts/build-ble-payment-sdk-artifacts.sh
```

Generated artifacts are written to `dist/ble-payment-sdk/` and are ignored by Git.
