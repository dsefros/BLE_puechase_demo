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
                title: "Bluetooth запускается",
                
message: "Bluetooth инициализируется. Подождите несколько секунд.",
                canStartScan: false,
                isBlocking: false
            )
        case .ready:
            return BleScannerStatus(
                title: "Bluetooth готов",
                
message: "Можно начать поиск терминала.",
                canStartScan: true,
                isBlocking: false
            )
        case .poweredOff:
            return BleScannerStatus(
                title: "Внимание",
                message: "Включите Bluetooth и повторите попытку.",
                canStartScan: false,
                isBlocking: true
            )
        case .unauthorized:
            return BleScannerStatus(
                title: "Нет доступа к Bluetooth",
                
message: "Разрешите приложению доступ к Bluetooth в настройках.",
                canStartScan: false,
                isBlocking: true
            )
        case .unsupported:
            return BleScannerStatus(
                title: "BLE is unsupported",
                
message: "Устройство не поддерживает Bluetooth Low Energy.",
                canStartScan: false,
                isBlocking: true
            )
        case .resetting:
            return BleScannerStatus(
                title: "Bluetooth перезапускается",
                
message: "Bluetooth временно перезапускается. Попробуйте ещё раз.",
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
