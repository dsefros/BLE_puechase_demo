import Foundation

public enum BlePacketProcessingResult: Equatable, Sendable {
    case accepted(BlePaymentCandidate)
    case rejected(BlePacketRejectReason)
}
