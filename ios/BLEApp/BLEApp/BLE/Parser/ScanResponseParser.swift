import Foundation

struct ParsedManufacturerData {
    let manufacturerID: UInt16
    let payload: Data
}

struct ScanResponseData {
    let amountMinor: UInt32
    let merchant: String
}

struct ScanResponseParser {
    private let fallbackMerchant = "Терминал Волна"

    func splitRawManufacturerData(_ rawData: Data) throws -> ParsedManufacturerData {
        // CoreBluetooth manufacturer data includes 2-byte company identifier in little-endian order.
        guard rawData.count >= 2 else { throw VolnaParserError.manufacturerDataTooShort(rawData.count) }
        let id = UInt16(rawData[0]) | (UInt16(rawData[1]) << 8)
        return ParsedManufacturerData(manufacturerID: id, payload: Data(rawData.dropFirst(2)))
    }

    func parse(manufacturerID: UInt16, payload: Data) throws -> ScanResponseData {
        guard manufacturerID == BleConfig.manufacturerID else { throw VolnaParserError.unsupportedManufacturerID(manufacturerID) }
        guard payload.count >= 4 else { throw VolnaParserError.manufacturerDataTooShort(payload.count) }

        let amountMinor = payload.prefix(4).reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
        guard amountMinor > 0 else { throw VolnaParserError.amountMustBePositive }

        let merchantBytes = payload.dropFirst(4)
        let merchant = decodeWindows1251(merchantBytes)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\0").union(.whitespacesAndNewlines))

        return ScanResponseData(amountMinor: amountMinor, merchant: merchant.isEmpty ? fallbackMerchant : merchant)
    }

    private func decodeWindows1251(_ bytes: Data.SubSequence) -> String {
        let data = Data(bytes)
        return String(data: data, encoding: .windowsCP1251) ?? ""
    }
}
