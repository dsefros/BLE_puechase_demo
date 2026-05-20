# BLE Payment SDK Artifact Manifest

Run the artifact build script from the repository root:

```bash
bash scripts/build-ble-payment-sdk-artifacts.sh
```

The script creates these handoff files under `dist/ble-payment-sdk/`:

- `BlePaymentKit-ios-spm.zip` — iOS BLE Payment Integration Kit archive containing `kit/ios/BlePaymentKit` plus iOS integration docs, CoreBluetooth reference mapper/scanner source, examples, and shared test vectors.
- `ble-payment-kit-android-source.zip` — Android BLE Payment Integration Kit archive containing `kit/android/ble-payment-kit` plus integration docs, reference scanner/mapper source, examples, and test vectors from `kit/android/ble-payment-integration-kit`.
- `ble-payment-sdk-docs.zip` — documentation and shared test-vector archive for `kit/docs`.
- `SHA256SUMS.txt` — SHA-256 checksums for the three zip archives.

`dist/` is generated output and must not be committed.
