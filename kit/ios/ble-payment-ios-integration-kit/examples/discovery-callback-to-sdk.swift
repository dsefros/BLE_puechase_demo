// Snippet (CoreBluetooth callback mapping)
import CoreBluetooth
import BlePaymentKit

let config = BlePaymentConfig.default
let mapper = BlePaymentAdvertisementMapper(config: config)
let sdk = BlePaymentKit(config: config)

func handleDiscovery(peripheral: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber) {
    // Mapper reads only service data for config.serviceUUID
    // and splits manufacturer bytes into manufacturerId + payload body.
    guard let input = mapper.map(
        advertisementData: advertisementData,
        rssi: rssi.intValue,
        peripheralIdentifier: peripheral.identifier.uuidString
    ) else {
        return
    }
    _ = sdk.process(input: input)
}
