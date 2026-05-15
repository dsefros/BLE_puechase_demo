import Foundation
import XCTest
@testable import BlePaymentKit

final class TestVectorLoadingTests: XCTestCase {
    func testAllSharedVectorsLoad() throws {
        for name in ["valid-packet", "wrong-prefix", "weak-rssi", "missing-field", "malformed-payload", "duplicate-packet", "unsupported-version", "expired-packet"] {
            let vector = try TestVector.load(name)
            XCTAssertFalse(vector.description.isEmpty)
            XCTAssertFalse(vector.advertisementDataHex.isEmpty)
            XCTAssertNotNil(try vector.input().timestamp)
        }
    }
}

struct TestVector: Decodable {
    let description: String
    let advertisementDataHex: String
    let scanResponseDataHex: String?
    let manufacturerId: UInt16?
    let rssi: Int
    let timestamp: String
    let deviceIdentifier: String
    let localName: String?
    let config: TestVectorConfig
    let expectedResult: String
    let expectedRejectReason: String?
    let expectedCandidate: ExpectedCandidate?

    static func load(_ name: String) throws -> TestVector {
        let fileName = "\(name).json"
        let currentDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let sourceDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let candidateDirectories = [
            currentDirectory.appendingPathComponent("kit").appendingPathComponent("docs").appendingPathComponent("test-vectors"),
            currentDirectory.appendingPathComponent("..").appendingPathComponent("..").appendingPathComponent("docs").appendingPathComponent("test-vectors"),
            sourceDirectory.appendingPathComponent("..").appendingPathComponent("..").appendingPathComponent("..").appendingPathComponent("..").appendingPathComponent("docs").appendingPathComponent("test-vectors"),
        ]

        for directory in candidateDirectories {
            let url = directory.appendingPathComponent(fileName).standardizedFileURL
            if FileManager.default.fileExists(atPath: url.path) {
                let data = try Data(contentsOf: url)
                return try JSONDecoder().decode(TestVector.self, from: data)
            }
        }

        let fallbackURL = candidateDirectories.last!.appendingPathComponent(fileName).standardizedFileURL
        let data = try Data(contentsOf: fallbackURL)
        return try JSONDecoder().decode(TestVector.self, from: data)
    }

    func input() throws -> BlePacketInput {
        guard let advertisementData = HexUtils.data(fromHex: advertisementDataHex) else { throw TestVectorError.invalidHex }
        let scanResponseData = scanResponseDataHex.flatMap(HexUtils.data(fromHex:))
        return BlePacketInput(advertisementData: advertisementData, scanResponseData: scanResponseData, manufacturerId: manufacturerId, rssi: rssi, timestamp: try Self.parse(timestamp), deviceIdentifier: deviceIdentifier, localName: localName)
    }

    static func parse(_ value: String) throws -> Date {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: value) else { throw TestVectorError.invalidDate }
        return date
    }
}

struct TestVectorConfig: Decodable {
    let serviceUUID: String
    let supportedPacketVersion: UInt8
    let requiredCapabilityMask: String
    let manufacturerId: String
    let rssiThreshold: Int
    let defaultMerchantName: String
    let qrLinkPrefix: String

    func toSwiftConfig() -> BlePaymentConfig {
        let mask = UInt8(requiredCapabilityMask.replacingOccurrences(of: "0x", with: ""), radix: 16) ?? 0x80
        let manufacturer = UInt16(manufacturerId.replacingOccurrences(of: "0x", with: ""), radix: 16) ?? 0xF001
        return BlePaymentConfig(serviceUUID: serviceUUID, supportedPacketVersion: supportedPacketVersion, requiredCapabilityMask: mask, manufacturerId: manufacturer, rssiThreshold: rssiThreshold, defaultMerchantName: defaultMerchantName, qrLinkPrefix: qrLinkPrefix)
    }
}

struct ExpectedCandidate: Decodable {
    let qrcId: String
    let qrLink: String
    let amountMinor: UInt32
    let merchantName: String
    let finalRssi: Int
    let rssiDelta: Int
}

enum TestVectorError: Error {
    case invalidHex
    case invalidDate
}
