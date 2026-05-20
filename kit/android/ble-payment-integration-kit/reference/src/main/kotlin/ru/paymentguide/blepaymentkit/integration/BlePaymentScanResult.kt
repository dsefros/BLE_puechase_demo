package ru.paymentguide.blepaymentkit.integration

import ru.paymentguide.blepaymentkit.BlePacketInput

sealed class BlePaymentScanResult {
    data class Mapped(val input: BlePacketInput) : BlePaymentScanResult()
    data object Ignored : BlePaymentScanResult()
}
