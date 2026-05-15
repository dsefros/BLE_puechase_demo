import XCTest
@testable import BlePaymentKit

final class BlePaymentKitTests: XCTestCase {
    func testAcceptedValidPacket() throws { try assertAccepted("valid-packet") }

    func testNoPrefixRuleMapsPlaceholderToUnsupportedVersion() throws {
        try assertRejected("wrong-prefix", .unsupportedVersion)
    }

    func testWeakRSSI() throws { try assertRejected("weak-rssi", .signalBelowThreshold) }
    func testMissingField() throws { try assertRejected("missing-field", .missingRequiredField) }
    func testMalformedPacket() throws { try assertRejected("malformed-payload", .malformedPayload) }
    func testUnsupportedVersion() throws { try assertRejected("unsupported-version", .unsupportedVersion) }

    func testDuplicatePlaceholderIsAcceptedBecauseCurrentAppHasNoDuplicatePolicy() throws {
        let vector = try TestVector.load("duplicate-packet")
        let sdk = BlePaymentKit(config: vector.config.toSwiftConfig())
        guard case .accepted = sdk.process(input: try vector.input()) else {
            return XCTFail("First processing should be accepted")
        }
        guard case .accepted = sdk.process(input: try vector.input()) else {
            return XCTFail("Duplicate placeholder should remain accepted for current BLEApp parity")
        }
    }

    func testExpiredPlaceholderIsAcceptedBecauseCurrentAppHasNoExpiryPolicy() throws {
        try assertAccepted("expired-packet")
    }

    private func assertAccepted(_ name: String) throws {
        let vector = try TestVector.load(name)
        let result = BlePaymentKit(config: vector.config.toSwiftConfig()).process(input: try vector.input())
        guard case .accepted(let candidate) = result else {
            return XCTFail("Expected accepted, got \(result)")
        }
        XCTAssertEqual(candidate.qrcId, vector.expectedCandidate?.qrcId)
        XCTAssertEqual(candidate.qrLink, vector.expectedCandidate?.qrLink)
        XCTAssertEqual(candidate.amountMinor, vector.expectedCandidate?.amountMinor)
        XCTAssertEqual(candidate.merchantName, vector.expectedCandidate?.merchantName)
        XCTAssertEqual(candidate.finalRssi, vector.expectedCandidate?.finalRssi)
        XCTAssertEqual(candidate.rssiDelta, vector.expectedCandidate?.rssiDelta)
    }

    private func assertRejected(_ name: String, _ reason: BlePacketRejectReason) throws {
        let vector = try TestVector.load(name)
        let result = BlePaymentKit(config: vector.config.toSwiftConfig()).process(input: try vector.input())
        XCTAssertEqual(result, .rejected(reason))
    }
}
