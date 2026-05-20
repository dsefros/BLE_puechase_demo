# Quick Start

1. Add `BlePaymentKit/` as a local Swift Package.
2. Create one shared config and pass it consistently to scanner + SDK:
```swift
import BlePaymentKit

let config = BlePaymentConfig.default
let scanner = BlePaymentCentralScanner(config: config) { result in
    switch result {
    case .candidate(let candidate):
        // candidate.qrcId, candidate.qrLink, candidate.amountMinor
        break
    case .rejected:
        // expected during noisy scanning
        break
    }
}
```
3. Start CoreBluetooth scanning through the reference scanner:
```swift
scanner.startScan()
```
4. The mapper selects service data by `config.serviceUUID` (not by arbitrary dictionary order), converts manufacturer data into `(manufacturerId + payload body)`, and builds `BlePacketInput`.
5. Continue/stop scanning according to app flow (for example, stop after first accepted candidate).
