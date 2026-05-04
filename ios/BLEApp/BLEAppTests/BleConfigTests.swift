import XCTest
@testable import BLEApp

final class BleConfigTests: XCTestCase {
    func testConstantsMatchContract() {
        XCTAssertEqual(BleConfig.serviceUUIDString, "0000534B-0000-1000-8000-00805F9B34FB")
        XCTAssertEqual(BleConfig.manufacturerID, 0xF001)
        XCTAssertEqual(BleConfig.defaultRSSIThreshold, -70)
        XCTAssertEqual(BleConfig.scanTimeoutSeconds, 10)
        XCTAssertEqual(BleConfig.requiredCapabilityMask, 0x80)
        XCTAssertEqual(BleConfig.supportedPacketVersion, 0b001)
    }
}
