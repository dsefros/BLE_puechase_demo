import Foundation

struct VolnaQrcIdConverter {
    private let alphabet = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ")

    func fromBinary(_ payload: Data) -> String {
        if payload.isEmpty { return "" }
        if payload.allSatisfy({ $0 == 0 }) { return "0" }

        var bytes = Array(payload)
        while let first = bytes.first, first == 0 { bytes.removeFirst() }

        var digits: [Character] = []
        while !bytes.isEmpty {
            var quotient: [UInt8] = []
            quotient.reserveCapacity(bytes.count)
            var remainder = 0

            for byte in bytes {
                let accumulator = remainder * 256 + Int(byte)
                let q = accumulator / 36
                remainder = accumulator % 36
                if !quotient.isEmpty || q > 0 {
                    quotient.append(UInt8(q))
                }
            }

            digits.append(alphabet[remainder])
            bytes = quotient
        }

        return String(digits.reversed())
    }
}
