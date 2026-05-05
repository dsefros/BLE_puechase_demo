import Foundation

protocol PaymentSubmissionServiceProtocol {
    func submit(candidate: PaymentCandidate) async -> PaymentSubmissionResult
}

enum PaymentSubmissionResult: Equatable {
    case success
    case failure(message: String)
}
