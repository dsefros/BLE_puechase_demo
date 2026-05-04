import Foundation

struct PaymentCandidate: Equatable {
    let qrcID: String
    let amountMinor: UInt32
    let merchant: String
    let device: BleDeviceCandidate
    let rssi: Int
    let finalRSSI: Int
    let rssiDelta: Int
}
