import Foundation

struct PlaceholderPaymentSubmissionService: PaymentSubmissionServiceProtocol {
    func submit(candidate: PaymentCandidate) async -> PaymentSubmissionResult {
        if candidate.qrcID.isEmpty {
            return .failure(message: "Placeholder submit rejected empty QRC ID")
        }
        return .success
    }
}
