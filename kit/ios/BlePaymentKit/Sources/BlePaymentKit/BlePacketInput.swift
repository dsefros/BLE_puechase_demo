import Foundation

public struct BlePacketInput: Equatable, Sendable {
    public let advertisementData: Data
    public let scanResponseData: Data?
    public let manufacturerId: UInt16?
    public let rssi: Int
    public let timestamp: Date
    public let deviceIdentifier: String
    public let localName: String?

    public init(
        advertisementData: Data,
        scanResponseData: Data?,
        manufacturerId: UInt16? = nil,
        rssi: Int,
        timestamp: Date,
        deviceIdentifier: String,
        localName: String?
    ) {
        self.advertisementData = advertisementData
        self.scanResponseData = scanResponseData
        self.manufacturerId = manufacturerId
        self.rssi = rssi
        self.timestamp = timestamp
        self.deviceIdentifier = deviceIdentifier
        self.localName = localName
    }
}
