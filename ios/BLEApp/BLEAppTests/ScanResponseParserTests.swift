import XCTest
@testable import BLEApp

final class ScanResponseParserTests: XCTestCase {
    let parser = ScanResponseParser()

    func testSplitRawManufacturerDataLittleEndianID() throws {
        let split = try parser.splitRawManufacturerData(Data([0x01, 0xF0, 0x00]))
        XCTAssertEqual(split.manufacturerID, 0xF001)
        XCTAssertEqual(split.payload, Data([0x00]))
    }

    func testPayloadTooShortRejects() { XCTAssertThrowsError(try parser.parse(manufacturerID: 0xF001, payload: Data([0x00,0x01,0x02]))) }
    func testAmountZeroRejects() { XCTAssertThrowsError(try parser.parse(manufacturerID: 0xF001, payload: Data([0,0,0,0]))) }
    func testAmountAndMerchantParse() throws {
        let p = Data([0x00,0x00,0x30,0x39]) + "Тест".data(using: .windowsCP1251)!
        let parsed = try parser.parse(manufacturerID: 0xF001, payload: p)
        XCTAssertEqual(parsed.amountMinor, 12345)
        XCTAssertEqual(parsed.merchant, "Тест")
    }
    func testBlankMerchantFallback() throws {
        let parsed = try parser.parse(manufacturerID: 0xF001, payload: Data([0,0,0,1,0x20,0x00]))
        XCTAssertEqual(parsed.merchant, "Терминал Волна")
    }
}
