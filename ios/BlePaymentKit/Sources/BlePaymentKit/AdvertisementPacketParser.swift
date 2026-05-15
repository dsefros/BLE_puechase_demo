import Foundation

public struct AdvertisementPacket: Equatable, Sendable {
    public let packetVersion: UInt8
    public let rssiDelta: Int
    public let capabilities: UInt8
    public let operationCounter: UInt8
    public let qrcId: String
    public let qrcPayload: Data
}

public struct AdvertisementPacketParser: Sendable {
    public init() {}

    public func parse(_ data: Data, config: BlePaymentConfig) -> Result<AdvertisementPacket, BlePacketRejectReason> {
        guard data.count >= 3 else { return .failure(.packetTooShort) }

        let versionAndDelta = data[0]
        let packetVersion = (versionAndDelta >> 5) & 0b111
        guard packetVersion == config.supportedPacketVersion else {
            return .failure(.unsupportedVersion)
        }

        let deltaBits = Int(versionAndDelta & 0b1_1111)
        let rssiDelta = (deltaBits & 0b1_0000) != 0 ? deltaBits - 0b10_0000 : deltaBits

        let capabilities = data[1]
        guard (capabilities & config.requiredCapabilityMask) == config.requiredCapabilityMask else {
            return .failure(.missingRequiredField)
        }

        let operationCounter = data[2]
        let qrcPayload = data.count > 3 ? Data(data.dropFirst(3)) : Data()
        let qrcId = ByteUtils.base36UnsignedBigEndian(qrcPayload)

        return .success(AdvertisementPacket(packetVersion: packetVersion, rssiDelta: rssiDelta, capabilities: capabilities, operationCounter: operationCounter, qrcId: qrcId, qrcPayload: qrcPayload))
    }
}
