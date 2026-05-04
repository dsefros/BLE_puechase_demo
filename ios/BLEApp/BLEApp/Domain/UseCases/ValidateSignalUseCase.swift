import Foundation

struct ValidateSignalUseCase {
    func isAcceptable(rssi: Int, delta: Int, threshold: Int = BleConfig.defaultRSSIThreshold) -> Bool {
        let finalRSSI = rssi - delta
        return finalRSSI >= threshold
    }
}
