package ru.paymentguide.blepaymentkit

class BlePaymentKit(
    private val config: BlePaymentConfig = BlePaymentConfig.default(),
    private val decoder: BlePayloadDecoder = BlePayloadDecoder(),
    private val signalValidator: SignalValidator = SignalValidator(),
    private val candidateValidator: PaymentCandidateValidator = PaymentCandidateValidator(),
) {
    fun process(input: BlePacketInput): BlePacketProcessingResult {
        val decoded = decoder.decode(input, config).getOrElse { error ->
            return BlePacketProcessingResult.Rejected((error as? PacketRejected)?.reason ?: BlePacketRejectReason.unknown)
        }
        val advertisement = decoded.first
        val scanResponse = decoded.second
        signalValidator.validate(input.rssi, advertisement.rssiDelta, config).let { validation ->
            if (validation is ValidationResult.Invalid) return BlePacketProcessingResult.Rejected(validation.reason)
        }
        val finalRssi = signalValidator.finalRssi(input.rssi, advertisement.rssiDelta)
        return BlePacketProcessingResult.Accepted(
            BlePaymentCandidate(
                qrcId = advertisement.qrcId,
                qrLink = candidateValidator.qrLink(advertisement.qrcId, config),
                amountMinor = scanResponse.amountMinor,
                merchantName = scanResponse.merchantName,
                packetVersion = advertisement.packetVersion,
                operationCounter = advertisement.operationCounter,
                rssi = input.rssi,
                finalRssi = finalRssi,
                rssiDelta = advertisement.rssiDelta,
                deviceIdentifier = input.deviceIdentifier,
                localName = input.localName,
                timestamp = input.timestamp,
            ),
        )
    }
}
