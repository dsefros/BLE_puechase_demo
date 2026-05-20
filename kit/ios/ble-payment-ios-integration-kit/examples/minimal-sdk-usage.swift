// Snippet (not standalone app target)
import Foundation
import BlePaymentKit

let sdk = BlePaymentKit(config: .default)
let input = BlePacketInput(
    advertisementData: Data([0x20, 0x80, 0x01, 0x12]),
    scanResponseData: Data([0x00, 0x00, 0x00, 0x64]),
    manufacturerId: 0xF001,
    rssi: -52,
    timestamp: Date(),
    deviceIdentifier: "device-1",
    localName: "BLE Payment"
)
let result = sdk.process(input: input)
