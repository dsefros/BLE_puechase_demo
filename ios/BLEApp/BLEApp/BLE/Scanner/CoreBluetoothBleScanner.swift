import CoreBluetooth
import Foundation

final class CoreBluetoothBleScanner: NSObject, BleScannerProtocol {
    var stateDidChange: ((BleScannerState) -> Void)?
    var advertisementDidDiscover: ((BleDiscoveredAdvertisement) -> Void)?

    private(set) var currentState: BleScannerState = .idle {
        didSet { stateDidChange?(currentState) }
    }
    private(set) var isScanning = false

    private let centralManager: CBCentralManager
    private let serviceUUID: CBUUID
    private let scanAllDevicesForDebug: Bool

    init(scanAllDevicesForDebug: Bool = false) {
        self.scanAllDevicesForDebug = scanAllDevicesForDebug
        self.serviceUUID = CBUUID(string: BleConfig.serviceUUIDString)
        self.centralManager = CBCentralManager(delegate: nil, queue: .main)
        super.init()
        self.centralManager.delegate = self
    }

    func startScan() -> BleScanResult {
        guard currentState == .ready || currentState == .scanning else {
            return .unavailable(currentState)
        }

        guard !isScanning else { return .started }

        let services: [CBUUID]? = scanAllDevicesForDebug ? nil : [serviceUUID]
        centralManager.scanForPeripherals(withServices: services, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        isScanning = true
        currentState = .scanning
        return .started
    }

    func stopScan() -> BleScanResult {
        guard isScanning else { return .stopped }

        centralManager.stopScan()
        isScanning = false
        currentState = centralStateToScannerState(centralManager.state)
        return .stopped
    }

    private func centralStateToScannerState(_ state: CBManagerState) -> BleScannerState {
        switch state {
        case .unknown:
            return .idle
        case .resetting:
            return .resetting
        case .unsupported:
            return .unsupported
        case .unauthorized:
            return .unauthorized
        case .poweredOff:
            return .poweredOff
        case .poweredOn:
            return isScanning ? .scanning : .ready
        @unknown default:
            return .idle
        }
    }
}

extension CoreBluetoothBleScanner: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if isScanning && central.state != .poweredOn {
            isScanning = false
        }
        currentState = centralStateToScannerState(central.state)
    }

    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        let advertisedServiceUUIDs = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID])?.map(\.uuidString) ?? []

        let serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data]
        let volnaServiceData = serviceData?[serviceUUID]
        let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data

        let event = BleDiscoveredAdvertisement(
            peripheralID: peripheral.identifier,
            peripheralName: peripheral.name,
            rssi: RSSI.intValue,
            serviceUUIDs: advertisedServiceUUIDs,
            volnaServiceData: volnaServiceData,
            manufacturerData: manufacturerData,
            timestamp: Date()
        )
        advertisementDidDiscover?(event)
    }
}
