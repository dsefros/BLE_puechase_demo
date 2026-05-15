import Foundation

public enum ValidationResult: Equatable, Sendable {
    case valid
    case invalid(BlePacketRejectReason)
}
