import Foundation

protocol BleScannerProtocol: AnyObject {
    var stateDidChange: ((BleScannerState) -> Void)? { get set }
    var advertisementDidDiscover: ((BleDiscoveredAdvertisement) -> Void)? { get set }

    var currentState: BleScannerState { get }
    var isScanning: Bool { get }

    func startScan() -> BleScanResult
    func stopScan() -> BleScanResult
}
