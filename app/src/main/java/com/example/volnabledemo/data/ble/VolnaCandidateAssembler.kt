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
        BleLog.d("BLE_Assembler", "=== Assembling candidate ===")
        BleLog.d("BLE_Assembler", "RSSI: $rssi, RSSI delta: ${advertisementPacket.rssiDelta}")
        BleLog.d("BLE_Assembler", "QR ID: ${advertisementPacket.qrcId}")
        BleLog.d("BLE_Assembler", "Amount: ${scanResponseData.amountMinor}")
        BleLog.d("BLE_Assembler", "Merchant: ${scanResponseData.merchantName}")

        val finalRssi = signalStrengthValidator.finalRssi(rssi, advertisementPacket.rssiDelta)
        BleLog.d("BLE_Assembler", "Final RSSI: $finalRssi")

        val isValid = signalStrengthValidator.isValid(rssi, advertisementPacket.rssiDelta)
        BleLog.d("BLE_Assembler", "Signal strength valid: $isValid")

        require(isValid) { "RSSI below threshold (final RSSI: $finalRssi)" }

        VolnaCandidate(
            qrcId = advertisementPacket.qrcId,
            qrLink = qrLinkBuilder.build(advertisementPacket.qrcId),
            amountMinor = scanResponseData.amountMinor,
            merchantName = scanResponseData.merchantName,
            rssi = rssi,
            rssiFinal = finalRssi,
        )
    }
}