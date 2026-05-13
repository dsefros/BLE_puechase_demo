import XCTest
@testable import BLEApp

@MainActor
final class HomeViewModelFlowTests: XCTestCase {
    func testValidCandidateTransitionsToReadyForConfirmation() async {
        let scanner = FakeBleScanner()
        let sut = HomeViewModel(container: AppContainer(scanner: scanner, paymentSubmissionService: FakePaymentSubmissionService(result: .success)))

        sut.startScan()
        await emitAndDrainMainActor(scanner: scanner, advertisement: makeAdvertisement(rssi: -55))

        guard case .readyForConfirmation(let candidate) = sut.flowState else {
            return XCTFail("Expected readyForConfirmation")
        }
        XCTAssertEqual(candidate.merchant, "Тест")
        XCTAssertFalse(sut.isScanning)
    }

    func testConfirmTransitionsToSubmittingThenSuccess() async {
        let scanner = FakeBleScanner()
        let sut = HomeViewModel(container: AppContainer(scanner: scanner, paymentSubmissionService: FakePaymentSubmissionService(result: .success)))

        sut.startScan()
        await emitAndDrainMainActor(scanner: scanner, advertisement: makeAdvertisement(rssi: -55))
        await sut.confirmPayment()

        guard case .paymentSuccess(let candidate) = sut.flowState else {
            return XCTFail("Expected paymentSuccess")
        }
        XCTAssertEqual(candidate.amountMinor, 12345)
    }


    func testConfirmFailureTransitionsToPaymentError() async {
        let scanner = FakeBleScanner()
        let sut = HomeViewModel(container: AppContainer(scanner: scanner, paymentSubmissionService: FakePaymentSubmissionService(result: .failure(message: "Failed"))))

        sut.startScan()
        await emitAndDrainMainActor(scanner: scanner, advertisement: makeAdvertisement(rssi: -55))
        await sut.confirmPayment()

        guard case .paymentError(_, let message) = sut.flowState else {
            return XCTFail("Expected paymentError")
        }
        XCTAssertEqual(message, "Failed")
    }

    func testConfirmInWrongStateDoesNotChangeFlowState() async {
        let scanner = FakeBleScanner()
        let sut = HomeViewModel(container: AppContainer(scanner: scanner, paymentSubmissionService: FakePaymentSubmissionService(result: .success)))
        XCTAssertEqual(sut.flowState, .idle)

        await sut.confirmPayment()

        XCTAssertEqual(sut.flowState, .idle)
    }

    func testReadyForConfirmationDoesNotAllowGenericStartScan() async {
        let scanner = FakeBleScanner()
        let sut = HomeViewModel(container: AppContainer(scanner: scanner, paymentSubmissionService: FakePaymentSubmissionService(result: .success)))

        sut.startScan()
        await emitAndDrainMainActor(scanner: scanner, advertisement: makeAdvertisement(rssi: -55))

        XCTAssertFalse(sut.canShowScanButtons)
        XCTAssertFalse(sut.canStartScanAction)
        XCTAssertFalse(sut.canStopScanAction)
    }

    func testSubmittingPaymentDoesNotAllowGenericScanActions() async {
        let scanner = FakeBleScanner()
        let service = DelayedFakePaymentSubmissionService()
        let sut = HomeViewModel(container: AppContainer(scanner: scanner, paymentSubmissionService: service))

        sut.startScan()
        await emitAndDrainMainActor(scanner: scanner, advertisement: makeAdvertisement(rssi: -55))

        let task = Task { await sut.confirmPayment() }
        await Task.yield()

        guard case .submittingPayment = sut.flowState else {
            return XCTFail("Expected submittingPayment")
        }
        XCTAssertFalse(sut.canShowScanButtons)
        XCTAssertFalse(sut.canStartScanAction)
        XCTAssertFalse(sut.canStopScanAction)

        service.continueSubmission()
        _ = await task.value
    }

    func testIdleReadyAllowsStartScan() async {
        let scanner = FakeBleScanner()
        let sut = HomeViewModel(container: AppContainer(scanner: scanner, paymentSubmissionService: FakePaymentSubmissionService(result: .success)))

        XCTAssertEqual(sut.flowState, .idle)
        XCTAssertTrue(sut.canShowScanButtons)
        XCTAssertTrue(sut.canStartScanAction)
        XCTAssertFalse(sut.canStopScanAction)
    }

    func testScanningAllowsStopScan() async {
        let scanner = FakeBleScanner()
        let sut = HomeViewModel(container: AppContainer(scanner: scanner, paymentSubmissionService: FakePaymentSubmissionService(result: .success)))

        sut.startScan()

        XCTAssertEqual(sut.flowState, .scanning)
        XCTAssertTrue(sut.canShowScanButtons)
        XCTAssertFalse(sut.canStartScanAction)
        XCTAssertTrue(sut.canStopScanAction)
    }

    func testScanTimeoutMovesFromScanningToRetryableScannerError() async {
        let scanner = FakeBleScanner()
        let sut = HomeViewModel(container: AppContainer(scanner: scanner), scanTimeoutSeconds: 0.01)

        sut.startScan()
        await sleep(milliseconds: 30)

        guard case .scannerUnavailable(let message) = sut.flowState else {
            return XCTFail("Expected scannerUnavailable after timeout")
        }
        XCTAssertEqual(message, "Терминал не найден. Попробуйте повторить сканирование.")
        XCTAssertFalse(sut.isScanning)
        XCTAssertEqual(scanner.stopScanCallCount, 1)
    }

    func testScanTimeoutFinalStateStaysRetryableErrorAfterStopScanStateCallback() async {
        let scanner = FakeBleScanner()
        scanner.stateToEmitOnStop = .poweredOff
        let sut = HomeViewModel(container: AppContainer(scanner: scanner), scanTimeoutSeconds: 0.01)

        sut.startScan()
        await sleep(milliseconds: 30)
        await Task.yield()
        await Task.yield()

        guard case .scannerUnavailable(let message) = sut.flowState else {
            return XCTFail("Expected timeout scannerUnavailable to remain visible")
        }
        XCTAssertEqual(message, "Терминал не найден. Попробуйте повторить сканирование.")
        XCTAssertFalse(sut.isScanning)
    }

    func testUnauthorizedBluetoothUsesRussianBlockingErrorMessage() async {
        let scanner = FakeBleScanner()
        scanner.currentState = .unauthorized
        let sut = HomeViewModel(container: AppContainer(scanner: scanner))

        sut.startScan()

        guard case .blockingError(let message) = sut.flowState else {
            return XCTFail("Expected blockingError for unauthorized Bluetooth")
        }
        XCTAssertEqual(message, "Нет разрешения на Bluetooth. Разрешите доступ к Bluetooth в настройках приложения и повторите сканирование.")
    }

    func testCancelScanCancelsTimeoutAndReturnsIdle() async {
        let scanner = FakeBleScanner()
        let sut = HomeViewModel(container: AppContainer(scanner: scanner), scanTimeoutSeconds: 0.01)

        sut.startScan()
        sut.stopScan()
        await sleep(milliseconds: 30)

        XCTAssertEqual(sut.flowState, .idle)
        XCTAssertFalse(sut.isScanning)
    }

    func testValidCandidateBeforeTimeoutCancelsTimeoutAndShowsReadyForConfirmation() async {
        let scanner = FakeBleScanner()
        let sut = HomeViewModel(container: AppContainer(scanner: scanner), scanTimeoutSeconds: 0.02)

        sut.startScan()
        await emitAndDrainMainActor(scanner: scanner, advertisement: makeAdvertisement(rssi: -55))
        await sleep(milliseconds: 40)

        guard case .readyForConfirmation(let candidate) = sut.flowState else {
            return XCTFail("Expected readyForConfirmation to survive past timeout")
        }
        XCTAssertEqual(candidate.merchant, "Тест")
        XCTAssertFalse(sut.isScanning)
    }

    func testRetryFromScannerUnavailableAndBlockingErrorAttemptsScanningAgain() async {
        let scanner = FakeBleScanner()
        scanner.currentState = .poweredOff
        let sut = HomeViewModel(container: AppContainer(scanner: scanner), scanTimeoutSeconds: 10)

        sut.startScan()
        XCTAssertEqual(scanner.startScanCallCount, 1)
        guard case .scannerUnavailable = sut.flowState else {
            return XCTFail("Expected scannerUnavailable")
        }

        scanner.currentState = .ready
        sut.retryCurrentError()
        XCTAssertEqual(scanner.startScanCallCount, 2)
        XCTAssertEqual(sut.flowState, .scanning)

        sut.stopScan()
        scanner.currentState = .unauthorized
        sut.startScan()
        XCTAssertEqual(scanner.startScanCallCount, 3)
        guard case .blockingError = sut.flowState else {
            return XCTFail("Expected blockingError")
        }

        scanner.currentState = .ready
        sut.retryCurrentError()
        XCTAssertEqual(scanner.startScanCallCount, 4)
        XCTAssertEqual(sut.flowState, .scanning)
    }

    func testCloseFromScannerErrorReturnsIdleWithoutRetryingScan() async {
        let scanner = FakeBleScanner()
        scanner.currentState = .poweredOff
        let sut = HomeViewModel(container: AppContainer(scanner: scanner))

        sut.startScan()
        XCTAssertEqual(scanner.startScanCallCount, 1)
        sut.closeCurrentError()

        XCTAssertEqual(sut.flowState, .idle)
        XCTAssertEqual(scanner.startScanCallCount, 1)
        XCTAssertFalse(sut.isScanning)
    }

    func testRetryFromPaymentErrorRestartsBleScanForMVPInsteadOfResubmittingPayment() async {
        let scanner = FakeBleScanner()
        let paymentService = FakePaymentSubmissionService(result: .failure(message: "Failed"))
        let sut = HomeViewModel(container: AppContainer(scanner: scanner, paymentSubmissionService: paymentService))

        sut.startScan()
        await emitAndDrainMainActor(scanner: scanner, advertisement: makeAdvertisement(rssi: -55))
        await sut.confirmPayment()
        guard case .paymentError = sut.flowState else {
            return XCTFail("Expected paymentError")
        }

        sut.retryCurrentError()

        XCTAssertEqual(sut.flowState, .scanning)
        XCTAssertEqual(scanner.startScanCallCount, 2)
        XCTAssertNil(sut.latestValidCandidate)
    }

    func testCancelReturnsToIdleWhenNotScanning() async {
        let scanner = FakeBleScanner()
        let sut = HomeViewModel(container: AppContainer(scanner: scanner))

        sut.startScan()
        await emitAndDrainMainActor(scanner: scanner, advertisement: makeAdvertisement(rssi: -55))
        sut.cancelConfirmation()

        XCTAssertEqual(sut.flowState, .idle)
        XCTAssertNil(sut.latestValidCandidate)
    }

    func testWeakCandidateDoesNotTransitionToReadyForConfirmation() async {
        let scanner = FakeBleScanner()
        let sut = HomeViewModel(container: AppContainer(scanner: scanner))

        sut.startScan()
        await emitAndDrainMainActor(scanner: scanner, advertisement: makeAdvertisement(rssi: -71))

        XCTAssertEqual(sut.flowState, .scanning)
        XCTAssertNil(sut.latestValidCandidate)
    }


    private func emitAndDrainMainActor(scanner: FakeBleScanner, advertisement: BleDiscoveredAdvertisement) async {
        scanner.emit(advertisement: advertisement)
        await Task.yield()
    }

    private func sleep(milliseconds: UInt64) async {
        try? await Task.sleep(nanoseconds: milliseconds * 1_000_000)
    }

    private func makeAdvertisement(rssi: Int) -> BleDiscoveredAdvertisement {
        let serviceData = Data([0x20, 0x80, 0x01, 0x01])
        let merchantPayload = "Тест".data(using: .windowsCP1251)!
        let manufacturerPayload = Data([0x00, 0x00, 0x30, 0x39]) + merchantPayload
        let manufacturerData = Data([0x01, 0xF0]) + manufacturerPayload

        return BleDiscoveredAdvertisement(
            peripheralID: UUID(),
            peripheralName: "Demo",
            rssi: rssi,
            serviceUUIDs: [BleConfig.serviceUUIDString],
            volnaServiceData: serviceData,
            manufacturerData: manufacturerData,
            timestamp: Date()
        )
    }
}

private final class FakeBleScanner: BleScannerProtocol {
    var stateDidChange: ((BleScannerState) -> Void)?
    var advertisementDidDiscover: ((BleDiscoveredAdvertisement) -> Void)?

    var currentState: BleScannerState = .ready
    var isScanning = false
    var stateToEmitOnStop: BleScannerState = .ready
    private(set) var startScanCallCount = 0
    private(set) var stopScanCallCount = 0

    func startScan() -> BleScanResult {
        startScanCallCount += 1
        guard currentState == .ready || currentState == .scanning else {
            return .unavailable(currentState)
        }

        isScanning = true
        currentState = .scanning
        stateDidChange?(.scanning)
        return .started
    }

    func stopScan() -> BleScanResult {
        stopScanCallCount += 1
        isScanning = false
        currentState = stateToEmitOnStop
        stateDidChange?(stateToEmitOnStop)
        return .stopped
    }

    func emit(advertisement: BleDiscoveredAdvertisement) {
        advertisementDidDiscover?(advertisement)
    }
}


private struct FakePaymentSubmissionService: PaymentSubmissionServiceProtocol {
    let result: PaymentSubmissionResult

    func submit(candidate: PaymentCandidate) async -> PaymentSubmissionResult {
        result
    }
}

private final class DelayedFakePaymentSubmissionService: PaymentSubmissionServiceProtocol {
    private var continuation: CheckedContinuation<PaymentSubmissionResult, Never>?

    func submit(candidate: PaymentCandidate) async -> PaymentSubmissionResult {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func continueSubmission() {
        continuation?.resume(returning: .success)
        continuation = nil
    }
}

#if DEBUG
@MainActor
extension HomeViewModelFlowTests {
    func testDemoPresentationScenariosArePreviewOnlyExceptLive() {
        for scenario in HomeDemoScenario.allCases where scenario != .live {
            let presentation = HomeScreenPresentation.demo(scenario)
            XCTAssertFalse(presentation.isLiveMode)
        }
    }

    func testDemoPresentationLiveMapsToInteractiveDefaults() {
        let presentation = HomeScreenPresentation.demo(.live)
        XCTAssertTrue(presentation.isLiveMode)
        XCTAssertTrue(presentation.canShowScanButtons)
        XCTAssertTrue(presentation.canStartScanAction)
        XCTAssertFalse(presentation.canStopScanAction)
        XCTAssertEqual(presentation.scannerState, .ready)
    }

    func testLivePresentationMapsFromViewModel() async {
        let scanner = FakeBleScanner()
        let sut = HomeViewModel(container: AppContainer(scanner: scanner, paymentSubmissionService: FakePaymentSubmissionService(result: .success)))

        let idle = HomeScreenPresentation.live(from: sut)
        XCTAssertTrue(idle.isLiveMode)
        XCTAssertTrue(idle.canStartScanAction)

        sut.startScan()
        let scanning = HomeScreenPresentation.live(from: sut)
        XCTAssertTrue(scanning.canShowScanButtons)
        XCTAssertFalse(scanning.canStartScanAction)
        XCTAssertTrue(scanning.canStopScanAction)
        XCTAssertEqual(scanning.flowState, .scanning)
    }
}
#endif
