import Foundation

public struct PaymentCandidateValidator: Sendable {
    public init() {}

    public func qrLink(qrcId: String, config: BlePaymentConfig) -> String {
        config.qrLinkPrefix.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/" + qrcId
    }
}
