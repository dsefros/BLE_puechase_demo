import Foundation

public enum ByteUtils {
    public static func unsignedBigEndianUInt32(_ data: Data) -> UInt32? {
        guard data.count >= 4 else { return nil }
        return data.prefix(4).reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
    }

    public static func base36UnsignedBigEndian(_ data: Data) -> String {
        guard !data.isEmpty else { return "" }
        var digits = [UInt8](data)
        if digits.allSatisfy({ $0 == 0 }) { return "0" }
        let alphabet = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        var output = ""
        while digits.contains(where: { $0 != 0 }) {
            var quotient: [UInt8] = []
            var remainder = 0
            for byte in digits {
                let accumulator = remainder * 256 + Int(byte)
                let q = accumulator / 36
                remainder = accumulator % 36
                if !quotient.isEmpty || q != 0 { quotient.append(UInt8(q)) }
            }
            output.insert(alphabet[remainder], at: output.startIndex)
            digits = quotient
        }
        return output
    }
}
