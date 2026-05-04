import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var flowState: PaymentFlowState = .idle
    @Published private(set) var scannerState: BleScannerState = .idle
    @Published private(set) var isScanning = false
    @Published private(set) var discoveredAdvertisements: [BleDiscoveredAdvertisement] = []
    @Published private(set) var latestValidCandidate: PaymentCandidate?
    @Published private(set) var latestParseRejection: String?

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
                self.processAdvertisement(event)
            }
        }
    }

    func startScan() {
        let result = container.scanner.startScan()
        isScanning = container.scanner.isScanning

        switch result {
        case .started:
            flowState = .scanning
        case .stopped:
            flowState = .idle
        case .unavailable(let state):
            if state == .unauthorized {
                flowState = .blockingError(message: "Bluetooth permission is not granted")
            } else {
                flowState = .scannerUnavailable(message: "Scanner unavailable: \(state.rawValue)")
            }
        }

        container.logger.log("Start scan result: \(result)")
    }

    func stopScan() {
        let result = container.scanner.stopScan()
        isScanning = container.scanner.isScanning
        if !isScanning, case .scanning = flowState {
            flowState = .idle
        }
        container.logger.log("Stop scan result: \(result)")
    }

    func confirmPayment() {
        guard case let .readyForConfirmation(candidate) = flowState else { return }
        flowState = .submittingPayment(candidate)
        let submission = submitPaymentPlaceholder(candidate)
        switch submission {
        case .success:
            flowState = .paymentSuccess(candidate)
        case .failure(let message):
            flowState = .paymentError(candidate, message: message)
        }
    }

    func cancelConfirmation() {
        latestValidCandidate = nil
        if isScanning {
            flowState = .scanning
        } else {
            flowState = .idle
        }
    }

    private func processAdvertisement(_ event: BleDiscoveredAdvertisement) {
        guard let serviceData = event.volnaServiceData,
              let rawManufacturer = event.manufacturerData else {
            latestParseRejection = "Missing Volna service/manufacturer data"
            return
        }

        do {
            let packet = try container.advertisementParser.parse(serviceData)
            let split = try container.scanResponseParser.splitRawManufacturerData(rawManufacturer)
            let scanResponse = try container.scanResponseParser.parse(manufacturerID: split.manufacturerID, payload: split.payload)
            guard let candidate = container.candidateAssembler.assemble(advertisement: event, parsedService: packet, parsedScanResponse: scanResponse) else {
                latestParseRejection = "Candidate rejected by RSSI threshold"
                return
            }
            latestParseRejection = nil
            latestValidCandidate = candidate
            _ = container.scanner.stopScan()
            isScanning = container.scanner.isScanning
            flowState = .readyForConfirmation(candidate)
        } catch {
            latestParseRejection = String(describing: error)
        }
    }

    private enum PlaceholderSubmitResult {
        case success
        case failure(message: String)
    }

    private func submitPaymentPlaceholder(_ candidate: PaymentCandidate) -> PlaceholderSubmitResult {
        if candidate.qrcID.isEmpty {
            return .failure(message: "Placeholder submit rejected empty QRC ID")
        }
        return .success
    }
}
