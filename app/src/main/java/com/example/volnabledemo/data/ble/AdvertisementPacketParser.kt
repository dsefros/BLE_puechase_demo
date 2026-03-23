package com.example.volnabledemo.data.ble

import com.example.volnabledemo.domain.model.AdvertisementPacket
import com.example.volnabledemo.domain.model.VolnaContract

class AdvertisementPacketParser(
    private val qrcIdConverter: VolnaQrcIdConverter = VolnaQrcIdConverter(),
) {
    fun parse(serviceData: ByteArray): Result<AdvertisementPacket> = runCatching {
        require(serviceData.size >= 24) { "Service data too short" }

        val versionAndDelta = serviceData[0].toInt() and 0xFF
        val packetVersion = (versionAndDelta shr 5) and 0b111
        require(packetVersion == VolnaContract.supportedPacketVersion) { "Unsupported packet version: $packetVersion" }

        val deltaBits = versionAndDelta and 0b1_1111
        val rssiDelta = if ((deltaBits and 0b1_0000) != 0) deltaBits - 0b100_000 else deltaBits

        val terminalCapabilities = serviceData[1].toInt() and 0xFF
        require((terminalCapabilities and VolnaContract.requiredOnlineC2bCapabilityMask) != 0) { "Online C2B capability not supported" }

        AdvertisementPacket(
            packetVersion = packetVersion,
            rssiDelta = rssiDelta,
            terminalCapabilities = terminalCapabilities,
            operationCounter = serviceData[2].toInt() and 0xFF,
            qrcId = qrcIdConverter.fromBinary(serviceData.copyOfRange(3, 24)),
        )
    }
}
