import Foundation
import CoreBluetooth
import BlePaymentKit

public struct BlePaymentAdvertisementMapper {
    private let config: BlePaymentConfig
    private let expectedServiceUUID: CBUUID

    public init(config: BlePaymentConfig = .default) {
        self.config = config
        self.expectedServiceUUID = CBUUID(string: config.serviceUUID)
    }

    public func map(advertisementData: [String: Any], rssi: Int, peripheralIdentifier: String, timestamp: Date = Date()) -> BlePacketInput? {
        guard let serviceDataMap = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data],
              let advPayload = serviceDataMap[expectedServiceUUID] else {
            return nil
        }

        let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        var manufacturerId: UInt16?
        var scanResponseData: Data?

        if let rawManufacturer = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data, rawManufacturer.count >= 2 {
            manufacturerId = UInt16(rawManufacturer[0]) | (UInt16(rawManufacturer[1]) << 8)
            scanResponseData = Data(rawManufacturer.dropFirst(2))
        }

        return BlePacketInput(
            advertisementData: advPayload,
            scanResponseData: scanResponseData,
            manufacturerId: manufacturerId,
            rssi: rssi,
            timestamp: timestamp,
            deviceIdentifier: peripheralIdentifier,
            localName: localName
        )
    }

    public func scanServiceUUID() -> CBUUID {
        expectedServiceUUID
    }
}
