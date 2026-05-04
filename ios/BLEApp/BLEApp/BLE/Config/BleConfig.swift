import Foundation

enum BleConfig {
    static let serviceUUIDString = "0000534B-0000-1000-8000-00805F9B34FB"
    static let manufacturerID: UInt16 = 0xF001
    static let defaultRSSIThreshold = -70
    static let scanTimeoutSeconds = 10
    static let requiredCapabilityMask: UInt8 = 0x80
    static let supportedPacketVersion: UInt8 = 0b001
}
