import Foundation

public struct BlePaymentCandidate: Equatable, Sendable {
    public let qrcId: String
    public let qrLink: String
    public let amountMinor: UInt32
    public let merchantName: String
    public let packetVersion: UInt8
    public let operationCounter: UInt8
    public let rssi: Int
    public let finalRssi: Int
    public let rssiDelta: Int
    public let deviceIdentifier: String
    public let localName: String?
    public let timestamp: Date

    public init(qrcId: String, qrLink: String, amountMinor: UInt32, merchantName: String, packetVersion: UInt8, operationCounter: UInt8, rssi: Int, finalRssi: Int, rssiDelta: Int, deviceIdentifier: String, localName: String?, timestamp: Date) {
        self.qrcId = qrcId
        self.qrLink = qrLink
        self.amountMinor = amountMinor
        self.merchantName = merchantName
        self.packetVersion = packetVersion
        self.operationCounter = operationCounter
        self.rssi = rssi
        self.finalRssi = finalRssi
        self.rssiDelta = rssiDelta
        self.deviceIdentifier = deviceIdentifier
        self.localName = localName
        self.timestamp = timestamp
    }
}
