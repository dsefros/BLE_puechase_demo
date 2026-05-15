package ru.paymentguide.blepaymentkit

import java.time.Instant

data class BlePacketInput(
    val advertisementData: ByteArray,
    val scanResponseData: ByteArray?,
    val manufacturerId: Int? = null,
    val rssi: Int,
    val timestamp: Instant,
    val deviceIdentifier: String,
    val localName: String?,
) {
    override fun equals(other: Any?): Boolean = other is BlePacketInput &&
        advertisementData.contentEquals(other.advertisementData) &&
        scanResponseData.contentEqualsNullable(other.scanResponseData) &&
        manufacturerId == other.manufacturerId &&
        rssi == other.rssi &&
        timestamp == other.timestamp &&
        deviceIdentifier == other.deviceIdentifier &&
        localName == other.localName

    override fun hashCode(): Int {
        var result = advertisementData.contentHashCode()
        result = 31 * result + (scanResponseData?.contentHashCode() ?: 0)
        result = 31 * result + (manufacturerId ?: 0)
        result = 31 * result + rssi
        result = 31 * result + timestamp.hashCode()
        result = 31 * result + deviceIdentifier.hashCode()
        result = 31 * result + (localName?.hashCode() ?: 0)
        return result
    }
}

private fun ByteArray?.contentEqualsNullable(other: ByteArray?): Boolean = when {
    this == null && other == null -> true
    this == null || other == null -> false
    else -> this.contentEquals(other)
}
