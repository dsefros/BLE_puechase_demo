import Foundation
import XCTest
@testable import BLEApp

final class BleScannerModelTests: XCTestCase {
    func testDiscoveredAdvertisementFlagsAndFields() {
        let peripheralID = UUID()
        let serviceData = Data([0x01, 0x02])
        let manufacturerData = Data([0xAA])
        let now = Date()

        let advertisement = BleDiscoveredAdvertisement(
            peripheralID: peripheralID,
            peripheralName: "Demo Tag",
            rssi: -65,
            serviceUUIDs: [BleConfig.serviceUUIDString],
            volnaServiceData: serviceData,
            manufacturerData: manufacturerData,
            timestamp: now
        )

        XCTAssertEqual(advertisement.peripheralID, peripheralID)
        XCTAssertEqual(advertisement.peripheralName, "Demo Tag")
        XCTAssertEqual(advertisement.rssi, -65)
        XCTAssertEqual(advertisement.volnaServiceData, serviceData)
        XCTAssertEqual(advertisement.manufacturerData, manufacturerData)
        XCTAssertTrue(advertisement.hasVolnaServiceData)
        XCTAssertTrue(advertisement.hasManufacturerData)
    }

    func testScanResultUnavailableStateIsEquatable() {
        XCTAssertEqual(BleScanResult.unavailable(.poweredOff), .unavailable(.poweredOff))
        XCTAssertNotEqual(BleScanResult.unavailable(.poweredOff), .unavailable(.ready))
    }

    func testScannerStateRawValues() {
        XCTAssertEqual(BleScannerState.scanning.rawValue, "scanning")
        XCTAssertEqual(BleScannerState.ready.rawValue, "ready")
    }
}
