# Overview

Layers:
1. **Android scanner layer**: starts/stops BLE scans and reads `ScanResult`.
2. **Packet-processing SDK** (`ble-payment-kit`): deterministic parsing/validation/candidate creation.
3. **Host app payment flow**: permissions UX, UI, payment confirmation, backend/API calls.

The SDK does not request permissions, start scans, render UI, or perform backend payment confirmation.
