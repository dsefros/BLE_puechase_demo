import Foundation

public struct ParsedManufacturerData: Equatable, Sendable {
    public let manufacturerId: UInt16
    public let payload: Data
}

public struct ScanResponsePayload: Equatable, Sendable {
    public let amountMinor: UInt32
    public let merchantName: String
}

public struct ScanResponseParser: Sendable {
    public init() {}

    public func splitRawManufacturerData(_ rawData: Data) -> Result<ParsedManufacturerData, BlePacketRejectReason> {
        guard rawData.count >= 2 else { return .failure(.malformedPayload) }
        let id = UInt16(rawData[0]) | (UInt16(rawData[1]) << 8)
        return .success(ParsedManufacturerData(manufacturerId: id, payload: Data(rawData.dropFirst(2))))
    }

    public func parse(manufacturerId: UInt16, payload: Data, config: BlePaymentConfig) -> Result<ScanResponsePayload, BlePacketRejectReason> {
        guard manufacturerId == config.manufacturerId else { return .failure(.missingRequiredField) }
        guard payload.count >= 4 else { return .failure(.malformedPayload) }
        guard let amount = ByteUtils.unsignedBigEndianUInt32(payload), amount > 0 else { return .failure(.malformedPayload) }

        let merchantData = payload.dropFirst(4)
        let decoded = String(data: Data(merchantData), encoding: .windowsCP1251) ?? ""
        let merchant = decoded.trimmingCharacters(in: CharacterSet(charactersIn: "\0").union(.whitespacesAndNewlines))
        return .success(ScanResponsePayload(amountMinor: amount, merchantName: merchant.isEmpty ? config.defaultMerchantName : merchant))
    }
}
