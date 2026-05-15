package ru.paymentguide.blepaymentkit

data class ParsedManufacturerData(
    val manufacturerId: Int,
    val payload: ByteArray,
)

data class ScanResponsePayload(
    val amountMinor: Long,
    val merchantName: String,
)

class ScanResponseParser {
    fun splitRawManufacturerData(rawData: ByteArray): Result<ParsedManufacturerData> = runCatching {
        if (rawData.size < 2) throw PacketRejected(BlePacketRejectReason.malformedPayload)
        val id = (rawData[0].toInt() and 0xFF) or ((rawData[1].toInt() and 0xFF) shl 8)
        ParsedManufacturerData(id, rawData.copyOfRange(2, rawData.size))
    }

    fun parse(manufacturerId: Int, payload: ByteArray, config: BlePaymentConfig): Result<ScanResponsePayload> = runCatching {
        if (manufacturerId != config.manufacturerId) throw PacketRejected(BlePacketRejectReason.missingRequiredField)
        val amount = ByteUtils.unsignedBigEndianUInt32(payload) ?: throw PacketRejected(BlePacketRejectReason.malformedPayload)
        if (amount <= 0) throw PacketRejected(BlePacketRejectReason.malformedPayload)
        val merchant = payload.copyOfRange(4, payload.size).toString(java.nio.charset.Charset.forName("windows-1251")).trimEnd('\u0000').trim()
        ScanResponsePayload(amount, merchant.ifBlank { config.defaultMerchantName })
    }
}
