package com.example.volnabledemo.data.ble

import com.example.volnabledemo.domain.model.AdvertisementPacket
import com.example.volnabledemo.domain.model.ScanResponseData
import com.example.volnabledemo.domain.model.VolnaCandidate

class VolnaCandidateAssembler(
    private val signalStrengthValidator: SignalStrengthValidator,
    private val qrLinkBuilder: QrLinkBuilder,
) {
    fun assemble(
        advertisementPacket: AdvertisementPacket,
        scanResponseData: ScanResponseData,
        rssi: Int,
    ): Result<VolnaCandidate> = runCatching {
        require(signalStrengthValidator.isValid(rssi, advertisementPacket.rssiDelta)) { "RSSI below threshold" }
        VolnaCandidate(
            qrcId = advertisementPacket.qrcId,
            qrLink = qrLinkBuilder.build(advertisementPacket.qrcId),
            amountMinor = scanResponseData.amountMinor,
            merchantName = scanResponseData.merchantName,
            rssi = rssi,
            rssiFinal = signalStrengthValidator.finalRssi(rssi, advertisementPacket.rssiDelta),
        )
    }
}
