import Foundation
import BlePaymentKit

public enum BlePaymentScanResult {
    case candidate(BlePaymentCandidate)
    case rejected(BlePacketRejectReason)
}
