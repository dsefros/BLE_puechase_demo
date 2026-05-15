import Foundation

public struct BlePaymentConfig: Equatable, Sendable {
    public let serviceUUID: String
    public let supportedPacketVersion: UInt8
    public let requiredCapabilityMask: UInt8
    public let manufacturerId: UInt16
    public let rssiThreshold: Int
    public let defaultMerchantName: String
    public let qrLinkPrefix: String

    public init(
        serviceUUID: String = "0000534B-0000-1000-8000-00805F9B34FB",
        supportedPacketVersion: UInt8 = 0b001,
        requiredCapabilityMask: UInt8 = 0x80,
        manufacturerId: UInt16 = 0xF001,
        rssiThreshold: Int = -70,
        defaultMerchantName: String = "Терминал Волна",
        qrLinkPrefix: String = "https://qr.nspk.ru"
    ) {
        self.serviceUUID = serviceUUID
        self.supportedPacketVersion = supportedPacketVersion
        self.requiredCapabilityMask = requiredCapabilityMask
        self.manufacturerId = manufacturerId
        self.rssiThreshold = rssiThreshold
        self.defaultMerchantName = defaultMerchantName
        self.qrLinkPrefix = qrLinkPrefix
    }

    public static let `default` = BlePaymentConfig()
}
