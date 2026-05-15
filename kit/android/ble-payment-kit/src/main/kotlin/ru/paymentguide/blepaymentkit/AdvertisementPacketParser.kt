package ru.paymentguide.blepaymentkit

data class AdvertisementPacket(
    val packetVersion: Int,
    val rssiDelta: Int,
    val terminalCapabilities: Int,
    val operationCounter: Int,
    val qrcId: String,
    val qrcPayload: ByteArray,
) {
    override fun equals(other: Any?): Boolean = other is AdvertisementPacket &&
        packetVersion == other.packetVersion &&
        rssiDelta == other.rssiDelta &&
        terminalCapabilities == other.terminalCapabilities &&
        operationCounter == other.operationCounter &&
        qrcId == other.qrcId &&
        qrcPayload.contentEquals(other.qrcPayload)

    override fun hashCode(): Int {
        var result = packetVersion
        result = 31 * result + rssiDelta
        result = 31 * result + terminalCapabilities
        result = 31 * result + operationCounter
        result = 31 * result + qrcId.hashCode()
        result = 31 * result + qrcPayload.contentHashCode()
        return result
    }
}

class AdvertisementPacketParser {
    fun parse(data: ByteArray, config: BlePaymentConfig): Result<AdvertisementPacket> = runCatching {
        if (data.size < 3) throw PacketRejected(BlePacketRejectReason.packetTooShort)
        val versionAndDelta = data[0].toInt() and 0xFF
        val packetVersion = (versionAndDelta shr 5) and 0b111
        if (packetVersion != config.supportedPacketVersion) throw PacketRejected(BlePacketRejectReason.unsupportedVersion)
        val deltaBits = versionAndDelta and 0b1_1111
        val rssiDelta = if ((deltaBits and 0b1_0000) != 0) deltaBits - 0b10_0000 else deltaBits
        val capabilities = data[1].toInt() and 0xFF
        if ((capabilities and config.requiredCapabilityMask) != config.requiredCapabilityMask) {
            throw PacketRejected(BlePacketRejectReason.missingRequiredField)
        }
        val payload = data.copyOfRange(3, data.size)
        AdvertisementPacket(packetVersion, rssiDelta, capabilities, data[2].toInt() and 0xFF, ByteUtils.base36UnsignedBigEndian(payload), payload)
    }
}
