# Recommended integration flow

1. User starts payment scan.
2. App verifies permissions + Bluetooth readiness.
3. App starts `BluetoothLeScanner`.
4. `ScanCallback` receives `ScanResult`.
5. Mapper converts `ScanResult` -> `BlePacketInput` (or `Ignored`).
6. SDK processes packet.
7. If `Accepted`, app should typically stop scanning and move into payment confirmation/submission flow.
8. If `Rejected`, keep scanning (optionally log reason).

Scanner stop policy is app-owned. A common policy is stop-on-first-accepted candidate, with optional de-duplication or confirmation rules in host app.
