import Foundation

struct BleScannerStatus: Equatable {
    let title: String
    let message: String
    let canStartScan: Bool
    let isBlocking: Bool
}

struct BleScannerStatusPresenter {
    func status(for state: BleScannerState, isScanning: Bool) -> BleScannerStatus {
        if isScanning || state == .scanning {
            return BleScannerStatus(
                title: "Scanning for payment terminal",
                message: "Hold near the terminal or tag while discovery runs in the foreground.",
                canStartScan: false,
                isBlocking: false
            )
        }

        switch state {
        case .idle:
            return BleScannerStatus(
                title: "Bluetooth not started",
                message: "Bluetooth is initializing. Please wait a moment.",
                canStartScan: false,
                isBlocking: false
            )
        case .ready:
            return BleScannerStatus(
                title: "Bluetooth ready",
                message: "You can start scanning for a payment terminal.",
                canStartScan: true,
                isBlocking: false
            )
        case .poweredOff:
            return BleScannerStatus(
                title: "Bluetooth is off",
                message: "Enable Bluetooth in system settings to scan for payment terminals.",
                canStartScan: false,
                isBlocking: true
            )
        case .unauthorized:
            return BleScannerStatus(
                title: "Bluetooth permission is missing",
                message: "Allow Bluetooth access for this app to discover payment terminals.",
                canStartScan: false,
                isBlocking: true
            )
        case .unsupported:
            return BleScannerStatus(
                title: "BLE is unsupported",
                message: "This device does not support Bluetooth Low Energy scanning.",
                canStartScan: false,
                isBlocking: true
            )
        case .resetting:
            return BleScannerStatus(
                title: "Bluetooth is resetting",
                message: "Bluetooth is temporarily resetting. Try scanning again shortly.",
                canStartScan: false,
                isBlocking: false
            )
        case .scanning:
            return BleScannerStatus(
                title: "Scanning for payment terminal",
                message: "Hold near the terminal or tag while discovery runs in the foreground.",
                canStartScan: false,
                isBlocking: false
            )
        }
    }
}
