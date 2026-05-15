import Foundation

public enum HexUtils {
    public static func data(fromHex hex: String) -> Data? {
        let cleaned = hex.filter { !$0.isWhitespace }
        guard cleaned.count.isMultiple(of: 2) else { return nil }
        var data = Data()
        var index = cleaned.startIndex
        while index < cleaned.endIndex {
            let next = cleaned.index(index, offsetBy: 2)
            guard let byte = UInt8(cleaned[index..<next], radix: 16) else { return nil }
            data.append(byte)
            index = next
        }
        return data
    }

    public static func hex(from data: Data) -> String {
        data.map { String(format: "%02X", $0) }.joined()
    }
}
