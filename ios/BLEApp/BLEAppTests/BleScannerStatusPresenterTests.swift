import XCTest
@testable import BLEApp

final class BleScannerStatusPresenterTests: XCTestCase {
    private let sut = BleScannerStatusPresenter()

    func testReadyCanStartScan() {
        let status = sut.status(for: .ready, isScanning: false)
        XCTAssertEqual(status.title, "Bluetooth ready")
        XCTAssertTrue(status.canStartScan)
        XCTAssertFalse(status.isBlocking)
    }

    func testScanningCannotStart() {
        let status = sut.status(for: .scanning, isScanning: true)
        XCTAssertFalse(status.canStartScan)
        XCTAssertEqual(status.title, "Scanning for payment terminal")
    }

    func testUnauthorizedIsBlocking() {
        let status = sut.status(for: .unauthorized, isScanning: false)
        XCTAssertEqual(status.title, "Bluetooth permission is missing")
        XCTAssertTrue(status.isBlocking)
    }

    func testPoweredOffIsBlocking() {
        let status = sut.status(for: .poweredOff, isScanning: false)
        XCTAssertEqual(status.title, "Bluetooth is off")
        XCTAssertTrue(status.isBlocking)
    }

    func testUnsupportedIsBlocking() {
        let status = sut.status(for: .unsupported, isScanning: false)
        XCTAssertEqual(status.title, "BLE is unsupported")
        XCTAssertTrue(status.isBlocking)
    }

    func testResettingDeterministicStatus() {
        let status = sut.status(for: .resetting, isScanning: false)
        XCTAssertEqual(status.title, "Bluetooth is resetting")
        XCTAssertEqual(status.message, "Bluetooth is temporarily resetting. Try scanning again shortly.")
    }

    func testIdleDeterministicStatus() {
        let status = sut.status(for: .idle, isScanning: false)
        XCTAssertEqual(status.title, "Bluetooth not started")
        XCTAssertEqual(status.message, "Bluetooth is initializing. Please wait a moment.")
    }
}
