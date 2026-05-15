import Foundation

struct PlaceholderPaymentSubmissionService: PaymentSubmissionServiceProtocol {

    private static let baseURL =
    "https://beta-ecom.payment-guide.ru/api/internal/sbp/pay"

    func submit(
        candidate: PaymentCandidate
    ) async -> PaymentSubmissionResult {

        guard !candidate.qrcID.isEmpty else {
            return .failure(message: "Empty qrcID")
        }

        guard var components = URLComponents(
            string: "\(Self.baseURL)/\(candidate.qrcID)"
        ) else {
            return .failure(message: "Bad URL")
        }

        components.queryItems = [
            URLQueryItem(
                name: "status",
                value: "SUCCESS"
            ),
            URLQueryItem(
                name: "statusCode",
                value: "SUCCESS"
            ),
            URLQueryItem(
                name: "statusMessage",
                value: "SUCCESS"
            )
        ]

        guard let url = components.url else {
            return .failure(message: "URL build failed")
        }

        print("PAYMENT_REQUEST:")
        print(url.absoluteString)

        do {

            let (_, response) =
                try await URLSession.shared.data(from: url)

            guard let http =
                response as? HTTPURLResponse
            else {
                return .failure(message: "Invalid response")
            }

            print("PAYMENT_STATUS:")
            print(http.statusCode)

            if (200...299).contains(http.statusCode) {
                return .success
            }

            if (400...499).contains(http.statusCode) {
                return .failure(
                    message: "Host rejected"
                )
            }

            return .failure(
                message: "Network"
            )

        } catch {

            print(error)

            return .failure(
                message: error.localizedDescription
            )
        }
    }
}
