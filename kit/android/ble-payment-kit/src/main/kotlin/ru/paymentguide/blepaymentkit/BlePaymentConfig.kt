package ru.paymentguide.blepaymentkit

data class BlePaymentConfig(
    val serviceUuid: String = "0000534B-0000-1000-8000-00805F9B34FB",
    val supportedPacketVersion: Int = 1,
    val requiredCapabilityMask: Int = 0x80,
    val manufacturerId: Int = 0xF001,
    val rssiThreshold: Int = -70,
    val defaultMerchantName: String = "Терминал Волна",
    val qrLinkPrefix: String = "https://qr.nspk.ru",
) {
    companion object {
        fun default(): BlePaymentConfig = BlePaymentConfig()
    }
}
