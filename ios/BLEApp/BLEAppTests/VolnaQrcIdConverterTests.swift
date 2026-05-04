import XCTest
@testable import BLEApp

final class VolnaQrcIdConverterTests: XCTestCase {
    let converter = VolnaQrcIdConverter()

    func testEmptyPayloadReturnsEmpty() { XCTAssertEqual(converter.fromBinary(Data()), "") }
    func testAllZeroPayloadReturnsZero() { XCTAssertEqual(converter.fromBinary(Data([0,0,0])), "0") }
    func testSingleByteValues() {
        XCTAssertEqual(converter.fromBinary(Data([0x01])), "1")
        XCTAssertEqual(converter.fromBinary(Data([0x23])), "Z")
    }
    func testMultiByteValue() { XCTAssertEqual(converter.fromBinary(Data([0x01, 0x00])), "74") }
}
