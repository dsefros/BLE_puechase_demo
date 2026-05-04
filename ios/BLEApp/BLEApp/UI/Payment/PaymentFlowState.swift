import Foundation

enum PaymentFlowState: Equatable {
    case idle
    case scanning
    case readyForConfirmation(PaymentCandidate)
    case submittingPayment(PaymentCandidate)
    case paymentSuccess(PaymentCandidate)
    case paymentError(PaymentCandidate, message: String)
    case scannerUnavailable(message: String)
    case blockingError(message: String)
}
