package ru.paymentguide.blepaymentkit

class PaymentCandidateValidator {
    fun qrLink(qrcId: String, config: BlePaymentConfig): String = config.qrLinkPrefix.trimEnd('/') + "/" + qrcId
}
