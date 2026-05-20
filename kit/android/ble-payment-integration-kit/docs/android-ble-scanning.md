# Android BLE scanning (host-app responsibilities)

`BlePaymentKit` does not scan. Your app owns scanner lifecycle.

## Practical checklist

- Confirm Bluetooth adapter exists and is enabled before starting scan.
- Request runtime permissions:
  - Android 12+ (API 31+): `BLUETOOTH_SCAN`.
  - Older Android: typically location permission for BLE scan results.
- Start scan with `BluetoothLeScanner.startScan(...)`.
- Stop scan with `BluetoothLeScanner.stopScan(...)` when:
  - you accepted a candidate and transition flow, or
  - timeout/user cancellation/lifecycle pause happens.

## ScanCallback role

`ScanCallback` receives `ScanResult`. The reference layer then:
1. extracts service data by configured service UUID,
2. extracts manufacturer payload by configured manufacturer ID,
3. maps to `BlePacketInput`,
4. calls `BlePaymentKit.process(...)`.

The reference code intentionally does not own permissions UX, lifecycle orchestration, retry policy, or UI.
