import Foundation

enum PaymentFlowState: String {
    case idle
    case scanningNotImplemented
    case readyForConfirmationPlaceholder
    case blockingErrorPlaceholder
}
