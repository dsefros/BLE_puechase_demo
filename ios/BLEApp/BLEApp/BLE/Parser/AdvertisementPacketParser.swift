import Foundation

struct AdvertisementPacket {
    let packetVersion: UInt8
    let rssiDelta: Int
    let capabilities: UInt8
    let operationCounter: UInt8
    let qrcID: String
    let qrcPayload: Data
}

enum VolnaParserError: Error, Equatable {
    case serviceDataTooShort(Int)
    case unsupportedPacketVersion(UInt8)
    case missingRequiredCapability(UInt8)
    case manufacturerDataTooShort(Int)
    case unsupportedManufacturerID(UInt16)
    case amountMustBePositive
}

struct AdvertisementPacketParser {
    private let converter = VolnaQrcIdConverter()

    func parse(_ data: Data) throws -> AdvertisementPacket {
        guard data.count >= 3 else { throw VolnaParserError.serviceDataTooShort(data.count) }

        let versionAndDelta = data[0]
        let packetVersion = (versionAndDelta >> 5) & 0b111
        guard packetVersion == BleConfig.supportedPacketVersion else {
            throw VolnaParserError.unsupportedPacketVersion(packetVersion)
        }

        let deltaBits = Int(versionAndDelta & 0b1_1111)
        let rssiDelta = (deltaBits & 0b1_0000) != 0 ? deltaBits - 0b10_0000 : deltaBits

        let capabilities = data[1]
        guard (capabilities & BleConfig.requiredCapabilityMask) == BleConfig.requiredCapabilityMask else {
            throw VolnaParserError.missingRequiredCapability(capabilities)
        }

        let operationCounter = data[2]
        let qrcPayload = data.count > 3 ? Data(data.dropFirst(3)) : Data()
        let qrcID = converter.fromBinary(qrcPayload)

        return AdvertisementPacket(
            packetVersion: packetVersion,
            rssiDelta: rssiDelta,
            capabilities: capabilities,
            operationCounter: operationCounter,
            qrcID: qrcID,
            qrcPayload: qrcPayload
        )
    }
}
