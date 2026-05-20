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
    private var activeScanID: UUID?
    private var lastDiagnosticsUpdate = Date.distantPast

    init(container: AppContainer, scanTimeoutSeconds: TimeInterval = TimeInterval(BleConfig.scanTimeoutSeconds)) {
        self.container = container
        self.scanTimeoutSeconds = scanTimeoutSeconds
        scannerState = container.scanner.currentState
        isScanning = container.scanner.isScanning

        container.scanner.stateDidChange = { [weak self] state in
            Task { @MainActor [weak self] in
                self?.handleScannerStateChange(state)
            }
        }

        container.scanner.advertisementDidDiscover = { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handleAdvertisement(event)
            }
        }
    }

    func startScan() {
        guard case .idle = flowState else { return }
        container.notificationService.prepareForRealScanStart()

        cancelScanTimeout()
        latestValidCandidate = nil
        setLatestParseRejection(nil)

        let scanID = UUID()
        activeScanID = scanID

        let result = container.scanner.startScan()
        refreshScannerSnapshot()

        switch result {
        case .started:
            setFlowState(.scanning)
            scheduleScanTimeout(for: scanID)
        case .stopped:
            activeScanID = nil
            setFlowState(.idle)
        case .unavailable(let state):
            activeScanID = nil
            setFlowState(scannerErrorState(for: state))
        }

        container.logger.log("Start scan result: \(result)")
    }

    func stopScan() {
        cancelScanTimeout()
        activeScanID = nil
        let result = container.scanner.stopScan()
        refreshScannerSnapshot()
        if case .scanning = flowState {
            setFlowState(.idle)
        }
        container.logger.log("Stop scan result: \(result)")
    }

    func retryCurrentError() {
        switch flowState {
        case .scannerUnavailable, .blockingError:
            returnToIdle()
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
        activeScanID = nil
        guard case let .readyForConfirmation(candidate) = flowState else { return }
        setFlowState(.submittingPayment(candidate))
        let submission = await container.paymentSubmissionService.submit(candidate: candidate)
        switch submission {
        case .success:
            container.notificationService.notifyPaymentSuccess(
                amount: RussianCurrencyFormatter.formatAmount(candidate.amountMinor),
                merchant: candidate.merchant
            )
            setFlowState(.paymentSuccess(candidate))
        case .failure(let message):
            container.notificationService.notifyPaymentError(
                amount: RussianCurrencyFormatter.formatAmount(candidate.amountMinor),
                merchant: candidate.merchant,
                error: message
            )
            setFlowState(.paymentError(candidate, message: message))
        }
    }

    func cancelConfirmation() {
        cancelScanTimeout()
        latestValidCandidate = nil
        refreshScannerSnapshot()
        if isScanning {
            let scanID = UUID()
            activeScanID = scanID
            setFlowState(.scanning)
            scheduleScanTimeout(for: scanID)
        } else {
            activeScanID = nil
            setFlowState(.idle)
        }
    }

    private func returnToIdle() {
        cancelScanTimeout()
        activeScanID = nil
        _ = container.scanner.stopScan()
        refreshScannerSnapshot()
        latestValidCandidate = nil
        setLatestParseRejection(nil)
        setFlowState(.idle)
    }

    private func handleScannerStateChange(_ state: BleScannerState) {
        setScannerState(state)
        setIsScanning(container.scanner.isScanning)

        guard activeScanID != nil, case .scanning = flowState else { return }
        let status = scannerStatusPresenter.status(for: state, isScanning: isScanning)
        if !isScanning, !status.canStartScan {
            cancelScanTimeout()
            activeScanID = nil
            setFlowState(scannerErrorState(for: state))
        }
    }

    private func handleAdvertisement(_ event: BleDiscoveredAdvertisement) {
        guard activeScanID != nil, case .scanning = flowState else { return }
        recordDiagnosticAdvertisement(event)
        processAdvertisement(event)
    }

    private func recordDiagnosticAdvertisement(_ event: BleDiscoveredAdvertisement) {
        #if DEBUG
        let now = Date()
        guard now.timeIntervalSince(lastDiagnosticsUpdate) >= 0.25 else { return }
        lastDiagnosticsUpdate = now
        var events = discoveredAdvertisements
        events.removeAll { $0.peripheralID == event.peripheralID }
        events.insert(event, at: 0)
        let trimmed = Array(events.prefix(maxEvents))
        if trimmed.map(\.peripheralID) != discoveredAdvertisements.map(\.peripheralID) {
            discoveredAdvertisements = trimmed
        }
        #endif
    }

    private func scheduleScanTimeout(for scanID: UUID) {
        guard scanTimeoutSeconds > 0 else { return }
        scanTimeoutTask?.cancel()
        let nanoseconds = UInt64(scanTimeoutSeconds * 1_000_000_000)
        scanTimeoutTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: nanoseconds)
            guard !Task.isCancelled else { return }
            self?.handleScanTimeout(for: scanID)
        }
    }

    private func cancelScanTimeout() {
        scanTimeoutTask?.cancel()
        scanTimeoutTask = nil
    }

    private func handleScanTimeout(for scanID: UUID) {
        guard activeScanID == scanID, case .scanning = flowState else { return }
        cancelScanTimeout()
        activeScanID = nil
        _ = container.scanner.stopScan()
        refreshScannerSnapshot()
        setFlowState(.scannerUnavailable(message: Self.scanTimeoutMessage))
    }

    private func scannerErrorState(for state: BleScannerState) -> PaymentFlowState {
        if state == .unauthorized {
            return .blockingError(message: Self.bluetoothPermissionMessage)
        }
        return .scannerUnavailable(message: scannerStatusPresenter.status(for: state, isScanning: false).title)
    }

    private func processAdvertisement(_ event: BleDiscoveredAdvertisement) {
        guard activeScanID != nil, case .scanning = flowState else { return }

        guard let serviceData = event.volnaServiceData,
              let rawManufacturer = event.manufacturerData else {
            setLatestParseRejection("Missing Volna service/manufacturer data")
            return
        }

        do {
            let packet = try container.advertisementParser.parse(serviceData)
            let split = try container.scanResponseParser.splitRawManufacturerData(rawManufacturer)
            let scanResponse = try container.scanResponseParser.parse(manufacturerID: split.manufacturerID, payload: split.payload)
            guard let candidate = container.candidateAssembler.assemble(advertisement: event, parsedService: packet, parsedScanResponse: scanResponse) else {
                setLatestParseRejection("Candidate rejected by RSSI threshold")
                return
            }
            setLatestParseRejection(nil)
            latestValidCandidate = candidate
            cancelScanTimeout()
            activeScanID = nil
            _ = container.scanner.stopScan()
            refreshScannerSnapshot()
            container.notificationService.notifyCandidateFound(
                amount: RussianCurrencyFormatter.formatAmount(candidate.amountMinor),
                merchant: candidate.merchant
            )
            setFlowState(.readyForConfirmation(candidate))
        } catch {
            setLatestParseRejection(String(describing: error))
        }
    }

    private func refreshScannerSnapshot() {
        setScannerState(container.scanner.currentState)
        setIsScanning(container.scanner.isScanning)
    }

    private func setFlowState(_ newValue: PaymentFlowState) {
        flowState = newValue
    }

    private func setScannerState(_ newValue: BleScannerState) {
        if scannerState != newValue {
            scannerState = newValue
        }
    }

    private func setIsScanning(_ newValue: Bool) {
        if isScanning != newValue {
            isScanning = newValue
        }
    }

    private func setLatestParseRejection(_ newValue: String?) {
        if latestParseRejection != newValue {
            latestParseRejection = newValue
        }
    }

    deinit {
        scanTimeoutTask?.cancel()
    }
}
