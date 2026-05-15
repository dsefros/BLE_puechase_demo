import Foundation

public enum BlePacketRejectReason: String, Error, Codable, Equatable, Sendable {
    case invalidPrefix
    case malformedPayload
    case missingRequiredField
    case weakRSSI
    case expiredPacket
    case unsupportedVersion
    case duplicatePacket
    case signalBelowThreshold
    case packetTooShort
    case invalidQrcId
    case unknown
}
