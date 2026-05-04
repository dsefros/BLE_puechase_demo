import Foundation

struct BleDeviceCandidate: Equatable {
    let peripheralIdentifier: String
    let rssi: Int
    let serviceUUID: String
}
