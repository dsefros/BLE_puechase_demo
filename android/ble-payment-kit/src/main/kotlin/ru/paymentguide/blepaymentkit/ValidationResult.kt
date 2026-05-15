package ru.paymentguide.blepaymentkit

sealed class ValidationResult {
    data object Valid : ValidationResult()
    data class Invalid(val reason: BlePacketRejectReason) : ValidationResult()
}
