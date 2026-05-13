import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var flowState: PaymentFlowState = .idle
    @Published private(set) var scannerState: BleScannerState = .idle
    @Published private(set) var isScanning = false
    @Published private(set) var discoveredAdvertisements: [BleDiscoveredAdvertisement] = []
    @Published private(set) var latestValidCandidate: PaymentCandidate?
    @Published private(set) var latestParseRejection: String?

    private let scannerStatusPresenter = BleScannerStatusPresenter()

    var scannerStatus: BleScannerStatus {
        scannerStatusPresenter.status(for: scannerState, isScanning: isScanning)
    }


    var canShowScanButtons: Bool {
        if case .idle = flowState { return true }
        if case .scanning = flowState { return true }
        return false
    }

    var canStartScanAction: Bool {
        guard case .idle = flowState else { return false }
        return scannerStatus.canStartScan
    }

    var canStopScanAction: Bool {
        guard case .scanning = flowState else { return false }
        return isScanning
    }

    private let container: AppContainer
    private let maxEvents = 20
    private static let scanTimeoutMessage = "Терминал не найден. Попробуйте повторить сканирование."
    private static let bluetoothPermissionMessage = "Нет разрешения на Bluetooth. Разрешите доступ к Bluetooth в настройках приложения и повторите сканирование."

    private let scanTimeoutSeconds: TimeInterval
    private var scanTimeoutTask: Task<Void, Never>?

    init(container: AppContainer, scanTimeoutSeconds: TimeInterval = TimeInterval(BleConfig.scanTimeoutSeconds)) {
        self.container = container
        self.scanTimeoutSeconds = scanTimeoutSeconds
        scannerState = container.scanner.currentState
        isScanning = container.scanner.isScanning

        container.scanner.stateDidChange = { [weak self] state in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.scannerState = state
                self.isScanning = self.container.scanner.isScanning

                if case .scanning = self.flowState, !self.isScanning, !self.scannerStatusPresenter.status(for: state, isScanning: false).canStartScan {
                    self.cancelScanTimeout()
                    self.flowState = self.scannerErrorState(for: state)
                }
            }
        }

        container.scanner.advertisementDidDiscover = { [weak self] event in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.discoveredAdvertisements.removeAll { $0.peripheralID == event.peripheralID }
                self.discoveredAdvertisements.insert(event, at: 0)
                self.discoveredAdvertisements = Array(self.discoveredAdvertisements.prefix(self.maxEvents))
                self.processAdvertisement(event)
            }
        }
    }

    func startScan() {
        cancelScanTimeout()
        latestValidCandidate = nil

        let result = container.scanner.startScan()
        isScanning = container.scanner.isScanning

        switch result {
        case .started:
            flowState = .scanning
            scheduleScanTimeout()
        case .stopped:
            flowState = .idle
        case .unavailable(let state):
            flowState = scannerErrorState(for: state)
        }

        container.logger.log("Start scan result: \(result)")
    }

    func stopScan() {
        cancelScanTimeout()
        let result = container.scanner.stopScan()
        isScanning = container.scanner.isScanning
        if !isScanning, case .scanning = flowState {
            flowState = .idle
        }
        container.logger.log("Stop scan result: \(result)")
    }

    func retryCurrentError() {
        switch flowState {
        case .scannerUnavailable, .blockingError:
            startScan()
        case .paymentError:
            // MVP retry semantics: restart BLE discovery rather than resubmitting a potentially stale payment.
            returnToIdle()
            startScan()
        default:
            break
        }
    }

    func closeCurrentError() {
        switch flowState {
        case .scannerUnavailable, .blockingError, .paymentError:
            returnToIdle()
        default:
            break
        }
    }

    func confirmPayment() async {
        cancelScanTimeout()
        guard case let .readyForConfirmation(candidate) = flowState else { return }
        flowState = .submittingPayment(candidate)
        let submission = await container.paymentSubmissionService.submit(candidate: candidate)
        switch submission {
        case .success:
            flowState = .paymentSuccess(candidate)
        case .failure(let message):
            flowState = .paymentError(candidate, message: message)
        }
    }

    func cancelConfirmation() {
        cancelScanTimeout()
        latestValidCandidate = nil
        if isScanning {
            flowState = .scanning
            scheduleScanTimeout()
        } else {
            flowState = .idle
        }
    }

    private func returnToIdle() {
        cancelScanTimeout()
        _ = container.scanner.stopScan()
        isScanning = container.scanner.isScanning
        latestValidCandidate = nil
        flowState = .idle
    }

    private func scheduleScanTimeout() {
        guard scanTimeoutSeconds > 0 else { return }
        scanTimeoutTask?.cancel()
        let nanoseconds = UInt64(scanTimeoutSeconds * 1_000_000_000)
        scanTimeoutTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: nanoseconds)
            guard !Task.isCancelled else { return }
            self?.handleScanTimeout()
        }
    }

    private func cancelScanTimeout() {
        scanTimeoutTask?.cancel()
        scanTimeoutTask = nil
    }

    @MainActor
    private func handleScanTimeout() {
        guard case .scanning = flowState else { return }
        _ = container.scanner.stopScan()
        isScanning = container.scanner.isScanning
        flowState = .scannerUnavailable(message: Self.scanTimeoutMessage)
        cancelScanTimeout()
    }

    private func scannerErrorState(for state: BleScannerState) -> PaymentFlowState {
        if state == .unauthorized {
            return .blockingError(message: Self.bluetoothPermissionMessage)
        }
        return .scannerUnavailable(message: scannerStatusPresenter.status(for: state, isScanning: false).title)
    }

    private func processAdvertisement(_ event: BleDiscoveredAdvertisement) {
        guard case .scanning = flowState else { return }

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
            cancelScanTimeout()
            _ = container.scanner.stopScan()
            isScanning = container.scanner.isScanning
            flowState = .readyForConfirmation(candidate)
        } catch {
            latestParseRejection = String(describing: error)
        }
    }

    deinit {
        scanTimeoutTask?.cancel()
    }
}
