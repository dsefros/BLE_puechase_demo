# Integration Flow

1. User initiates payment scan in app UI.
2. App checks Bluetooth readiness/authorization.
3. App starts CoreBluetooth scanning for `config.serviceUUID`.
4. `didDiscover` callback receives `advertisementData` and `RSSI`.
5. Mapper extracts service data by configured UUID and converts manufacturer bytes into `manufacturerId` + payload body.
6. Mapper builds `BlePacketInput` and passes it to `BlePaymentKit.process`.
7. App handles accepted candidate (continue payment flow) or rejection (typically diagnostic/noise).
8. App decides when to stop scan (first match, timeout, or manual stop).
