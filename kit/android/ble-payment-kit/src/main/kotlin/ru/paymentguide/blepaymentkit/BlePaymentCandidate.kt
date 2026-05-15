package ru.paymentguide.blepaymentkit

import java.time.Instant

data class BlePaymentCandidate(
    val qrcId: String,
    val qrLink: String,
    val amountMinor: Long,
    val merchantName: String,
    val packetVersion: Int,
    val operationCounter: Int,
    val rssi: Int,
    val finalRssi: Int,
    val rssiDelta: Int,
    val deviceIdentifier: String,
    val localName: String?,
    val timestamp: Instant,
)
