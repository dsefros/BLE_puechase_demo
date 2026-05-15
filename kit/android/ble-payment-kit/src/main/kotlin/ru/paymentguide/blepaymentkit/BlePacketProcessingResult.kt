package ru.paymentguide.blepaymentkit

sealed class BlePacketProcessingResult {
    data class Accepted(val candidate: BlePaymentCandidate) : BlePacketProcessingResult()
    data class Rejected(val reason: BlePacketRejectReason) : BlePacketProcessingResult()
}
