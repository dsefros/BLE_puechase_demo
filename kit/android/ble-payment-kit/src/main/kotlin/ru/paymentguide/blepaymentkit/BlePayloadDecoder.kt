package ru.paymentguide.blepaymentkit

class BlePayloadDecoder(
    private val advertisementPacketParser: AdvertisementPacketParser = AdvertisementPacketParser(),
    private val scanResponseParser: ScanResponseParser = ScanResponseParser(),
) {
    fun decode(input: BlePacketInput, config: BlePaymentConfig): Result<Pair<AdvertisementPacket, ScanResponsePayload>> = runCatching {
        val scanResponseData = input.scanResponseData ?: throw PacketRejected(BlePacketRejectReason.missingRequiredField)
        val advertisement = advertisementPacketParser.parse(input.advertisementData, config).getOrElse { throw it }
        val scanResponse = scanResponseParser.parse(input.manufacturerId ?: config.manufacturerId, scanResponseData, config).getOrElse { throw it }
        advertisement to scanResponse
    }
}
