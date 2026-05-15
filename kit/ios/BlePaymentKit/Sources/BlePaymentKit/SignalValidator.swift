import Foundation

public struct SignalValidator: Sendable {
    public init() {}

    public func finalRssi(rssi: Int, rssiDelta: Int) -> Int { rssi - rssiDelta }

    public func validate(rssi: Int, rssiDelta: Int, config: BlePaymentConfig) -> ValidationResult {
        finalRssi(rssi: rssi, rssiDelta: rssiDelta) >= config.rssiThreshold ? .valid : .invalid(.signalBelowThreshold)
    }
}
