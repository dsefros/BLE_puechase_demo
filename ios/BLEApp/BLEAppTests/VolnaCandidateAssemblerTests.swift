import XCTest
@testable import BLEApp

final class VolnaCandidateAssemblerTests: XCTestCase {
    let assembler = VolnaCandidateAssembler()
    func makeAd(rssi: Int) -> BleDiscoveredAdvertisement {
        BleDiscoveredAdvertisement(peripheralID: UUID(), peripheralName: "dev", rssi: rssi, serviceUUIDs: [], volnaServiceData: nil, manufacturerData: nil, timestamp: Date())
    }

    func testAssembleSuccess() {
        let packet = AdvertisementPacket(packetVersion: 1, rssiDelta: 2, capabilities: 0x80, operationCounter: 1, qrcID: "ABC", qrcPayload: Data())
        let resp = ScanResponseData(amountMinor: 100, merchant: "Магазин")
        let c = assembler.assemble(advertisement: makeAd(rssi: -60), parsedService: packet, parsedScanResponse: resp, threshold: -70)
        XCTAssertNotNil(c)
        XCTAssertEqual(c?.finalRSSI, -62)
    }

    func testAssembleRejectWeakSignal() {
        let packet = AdvertisementPacket(packetVersion: 1, rssiDelta: 5, capabilities: 0x80, operationCounter: 1, qrcID: "ABC", qrcPayload: Data())
        let resp = ScanResponseData(amountMinor: 100, merchant: "M")
        XCTAssertNil(assembler.assemble(advertisement: makeAd(rssi: -68), parsedService: packet, parsedScanResponse: resp, threshold: -70))
    }
}
