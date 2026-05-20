# Overview

The iOS BLE Payment Integration Kit combines:
1. CoreBluetooth host-side scan integration (in this kit's `reference/`).
2. `BlePaymentKit` packet-processing SDK (`BlePaymentKit/`).
3. Your host app payment flow.

`BlePaymentKit` does **not** request Bluetooth permissions, start/stop scanning, render UI, or submit payment/backend confirmation.
