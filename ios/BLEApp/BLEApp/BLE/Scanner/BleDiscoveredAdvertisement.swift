import Foundation

struct BleDiscoveredAdvertisement: Identifiable, Equatable {
    let peripheralID: UUID
    let peripheralName: String?
    let rssi: Int
    let serviceUUIDs: [String]
    let volnaServiceData: Data?
    let manufacturerData: Data?
    let timestamp: Date

    var id: UUID { peripheralID }
    var hasVolnaServiceData: Bool { volnaServiceData != nil }
    var hasManufacturerData: Bool { manufacturerData != nil }
}
