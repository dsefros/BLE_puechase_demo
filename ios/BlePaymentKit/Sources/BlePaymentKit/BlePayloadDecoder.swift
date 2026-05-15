import Foundation

public struct BlePayloadDecoder: Sendable {
    private let advertisementParser: AdvertisementPacketParser
    private let scanResponseParser: ScanResponseParser

    public init(advertisementParser: AdvertisementPacketParser = AdvertisementPacketParser(), scanResponseParser: ScanResponseParser = ScanResponseParser()) {
        self.advertisementParser = advertisementParser
        self.scanResponseParser = scanResponseParser
    }

    public func decode(input: BlePacketInput, config: BlePaymentConfig) -> Result<(AdvertisementPacket, ScanResponsePayload), BlePacketRejectReason> {
        guard let scanResponseData = input.scanResponseData else { return .failure(.missingRequiredField) }
        switch advertisementParser.parse(input.advertisementData, config: config) {
        case .failure(let reason): return .failure(reason)
        case .success(let advertisement):
            let manufacturerId = input.manufacturerId ?? config.manufacturerId
            switch scanResponseParser.parse(manufacturerId: manufacturerId, payload: scanResponseData, config: config) {
            case .failure(let reason): return .failure(reason)
            case .success(let scanResponse): return .success((advertisement, scanResponse))
            }
        }
    }
}
