import Foundation

struct VolnaCandidateAssembler {
    func assemble(advertisement: BleDiscoveredAdvertisement,
                  parsedService: AdvertisementPacket,
                  parsedScanResponse: ScanResponseData,
                  threshold: Int = BleConfig.defaultRSSIThreshold) -> PaymentCandidate? {
        let finalRSSI = advertisement.rssi - parsedService.rssiDelta
        guard finalRSSI >= threshold else { return nil }

        return PaymentCandidate(
            qrcID: parsedService.qrcID,
            amountMinor: parsedScanResponse.amountMinor,
            merchant: parsedScanResponse.merchant,
            device: BleDeviceCandidate(peripheralIdentifier: advertisement.peripheralID.uuidString, peripheralName: advertisement.peripheralName, rssi: advertisement.rssi, serviceUUID: BleConfig.serviceUUIDString),
            rssi: advertisement.rssi,
            finalRSSI: finalRSSI,
            rssiDelta: parsedService.rssiDelta
        )
    }
}
