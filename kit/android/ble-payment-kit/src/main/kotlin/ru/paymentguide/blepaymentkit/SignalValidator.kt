package ru.paymentguide.blepaymentkit

class SignalValidator {
    fun finalRssi(rssi: Int, rssiDelta: Int): Int = rssi - rssiDelta

    fun validate(rssi: Int, rssiDelta: Int, config: BlePaymentConfig): ValidationResult =
        if (finalRssi(rssi, rssiDelta) >= config.rssiThreshold) ValidationResult.Valid
        else ValidationResult.Invalid(BlePacketRejectReason.signalBelowThreshold)
}
