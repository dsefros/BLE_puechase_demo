import Foundation

final class HomeViewModel: ObservableObject {
    @Published private(set) var flowState: PaymentFlowState = .idle

    private let container: AppContainer

    init(container: AppContainer) {
        self.container = container
    }

    func startScanPlaceholder() {
        flowState = .scanningNotImplemented
        container.logger.log("Scan requested, placeholder only.")
    }
}
