import XCTest
@testable import BLEApp

@MainActor
final class HomeViewModelFlowTests: XCTestCase {
    func testValidCandidateTransitionsToReadyForConfirmation() async {
        let scanner = FakeBleScanner()
        let sut = HomeViewModel(container: AppContainer(scanner: scanner))

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
        let sut = HomeViewModel(container: AppContainer(scanner: scanner))

        sut.startScan()
        await emitAndDrainMainActor(scanner: scanner, advertisement: makeAdvertisement(rssi: -55))
        sut.confirmPayment()

        guard case .paymentSuccess(let candidate) = sut.flowState else {
            return XCTFail("Expected paymentSuccess")
        }
        XCTAssertEqual(candidate.amountMinor, 12345)
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

    func startScan() -> BleScanResult {
        isScanning = true
        currentState = .scanning
        stateDidChange?(.scanning)
        return .started
    }

    func stopScan() -> BleScanResult {
        isScanning = false
        currentState = .ready
        stateDidChange?(.ready)
        return .stopped
    }

    func emit(advertisement: BleDiscoveredAdvertisement) {
        advertisementDidDiscover?(advertisement)
    }
}
