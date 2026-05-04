import Foundation

final class BleScannerPlaceholder: BleScannerProtocol {
    var stateDidChange: ((BleScannerState) -> Void)?
    var advertisementDidDiscover: ((BleDiscoveredAdvertisement) -> Void)?
    private(set) var currentState: BleScannerState = .idle
    private(set) var isScanning = false

    func startScan() -> BleScanResult {
        isScanning = true
        currentState = .scanning
        stateDidChange?(currentState)
        return .started
    }

    func stopScan() -> BleScanResult {
        isScanning = false
        currentState = .idle
        stateDidChange?(currentState)
        return .stopped
    }
}
