import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var flowState: PaymentFlowState = .idle
    @Published private(set) var scannerState: BleScannerState = .idle
    @Published private(set) var isScanning = false
    @Published private(set) var discoveredAdvertisements: [BleDiscoveredAdvertisement] = []

    private let container: AppContainer
    private let maxEvents = 20

    init(container: AppContainer) {
        self.container = container
        scannerState = container.scanner.currentState
        isScanning = container.scanner.isScanning

        container.scanner.stateDidChange = { [weak self] state in
            guard let self else { return }
            Task { @MainActor in
                self.scannerState = state
                self.isScanning = self.container.scanner.isScanning
            }
        }

        container.scanner.advertisementDidDiscover = { [weak self] event in
            guard let self else { return }
            Task { @MainActor in
                self.discoveredAdvertisements.removeAll { $0.peripheralID == event.peripheralID }
                self.discoveredAdvertisements.insert(event, at: 0)
                self.discoveredAdvertisements = Array(self.discoveredAdvertisements.prefix(self.maxEvents))
            }
        }
    }

    func startScan() {
        let result = container.scanner.startScan()
        isScanning = container.scanner.isScanning
        flowState = .scanningNotImplemented
        container.logger.log("Start scan result: \(result)")
    }

    func stopScan() {
        let result = container.scanner.stopScan()
        isScanning = container.scanner.isScanning
        container.logger.log("Stop scan result: \(result)")
    }
}
