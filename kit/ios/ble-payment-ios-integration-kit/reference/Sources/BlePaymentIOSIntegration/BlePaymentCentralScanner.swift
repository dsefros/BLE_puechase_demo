import Foundation
import CoreBluetooth
import BlePaymentKit

public final class BlePaymentCentralScanner: NSObject, CBCentralManagerDelegate {
    private let sdk: BlePaymentKit
    private let mapper: BlePaymentAdvertisementMapper
    private let onResult: (BlePaymentScanResult) -> Void
    private var central: CBCentralManager!

    public init(config: BlePaymentConfig = .default, onResult: @escaping (BlePaymentScanResult) -> Void) {
        self.sdk = BlePaymentKit(config: config)
        self.mapper = BlePaymentAdvertisementMapper(config: config)
        self.onResult = onResult
        super.init()
        self.central = CBCentralManager(delegate: self, queue: nil)
    }

    public init(sdk: BlePaymentKit, mapper: BlePaymentAdvertisementMapper, onResult: @escaping (BlePaymentScanResult) -> Void) {
        self.sdk = sdk
        self.mapper = mapper
        self.onResult = onResult
        super.init()
        self.central = CBCentralManager(delegate: self, queue: nil)
    }

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {}

    public func startScan() {
        central.scanForPeripherals(withServices: [mapper.scanServiceUUID()], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }

    public func stopScan() {
        central.stopScan()
    }

    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let input = mapper.map(advertisementData: advertisementData, rssi: RSSI.intValue, peripheralIdentifier: peripheral.identifier.uuidString) else {
            return
        }
        switch sdk.process(input: input) {
        case .accepted(let candidate): onResult(.candidate(candidate))
        case .rejected(let reason): onResult(.rejected(reason))
        }
    }
}
