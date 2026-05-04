import XCTest
@testable import BLEApp

final class AdvertisementPacketParserTests: XCTestCase {
    let parser = AdvertisementPacketParser()

    func testTooShortRejects() { XCTAssertThrowsError(try parser.parse(Data([0x20,0x80]))) }
    func testUnsupportedVersionRejects() { XCTAssertThrowsError(try parser.parse(Data([0x40,0x80,0x01]))) }
    func testMissingCapabilityRejects() { XCTAssertThrowsError(try parser.parse(Data([0x20,0x01,0x01]))) }
    func testSigned5BitDeltas() throws {
        func delta(_ bits: UInt8) throws -> Int { try parser.parse(Data([(0b001 << 5) | bits, 0x80, 0x01])).rssiDelta }
        XCTAssertEqual(try delta(0b00000), 0)
        XCTAssertEqual(try delta(0b00001), 1)
        XCTAssertEqual(try delta(0b01111), 15)
        XCTAssertEqual(try delta(0b10000), -16)
        XCTAssertEqual(try delta(0b11111), -1)
    }
}
