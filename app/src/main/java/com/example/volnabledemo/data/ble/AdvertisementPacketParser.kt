package com.example.volnabledemo.data.ble

import com.example.volnabledemo.domain.model.AdvertisementPacket
import com.example.volnabledemo.domain.model.VolnaContract

class AdvertisementPacketParser(
    private val qrcIdConverter: VolnaQrcIdConverter = VolnaQrcIdConverter(),
) {
    fun parse(serviceData: ByteArray): Result<AdvertisementPacket> = runCatching {
        BleLog.d("BLE_Parser", "=== Parsing serviceData ===")
        BleLog.d("BLE_Parser", "ServiceData size: ${serviceData.size}")
        BleLog.d("BLE_Parser", "ServiceData hex: ${serviceData.joinToString("") { "%02x".format(it) }}")

        require(serviceData.size >= 3) {
            "Service data too short: need at least 3 bytes, got ${serviceData.size}"
        }

        val versionAndDelta = serviceData[0].toInt() and 0xFF
        val packetVersion = (versionAndDelta shr 5) and 0b111
        BleLog.d("BLE_Parser", "Packet version: $packetVersion, expected: ${VolnaContract.supportedPacketVersion}")
        require(packetVersion == VolnaContract.supportedPacketVersion) {
            "Unsupported packet version: $packetVersion"
        }

        val deltaBits = versionAndDelta and 0b1_1111
        val rssiDelta = if ((deltaBits and 0b1_0000) != 0) deltaBits - 0b100_000 else deltaBits
        BleLog.d("BLE_Parser", "RSSI delta: $rssiDelta")

        val terminalCapabilities = serviceData[1].toInt() and 0xFF
        BleLog.d("BLE_Parser", "Terminal capabilities: 0x${terminalCapabilities.toString(16)}")
        require((terminalCapabilities and VolnaContract.requiredOnlineC2bCapabilityMask) == VolnaContract.requiredOnlineC2bCapabilityMask) {
            "Online C2B capability not supported: 0x${terminalCapabilities.toString(16)}"
        }

        val operationCounter = serviceData[2].toInt() and 0xFF
        BleLog.d("BLE_Parser", "Operation counter: $operationCounter")

        val qrcIdBytes = if (serviceData.size > 3) {
            serviceData.copyOfRange(3, serviceData.size)
        } else {
            byteArrayOf()
        }
        BleLog.d("BLE_Parser", "QR ID bytes size: ${qrcIdBytes.size}")

        val qrcId = qrcIdConverter.fromBinary(qrcIdBytes)
        BleLog.d("BLE_Parser", "QR ID: $qrcId")
        BleLog.d("BLE_Parser", "=== Parse SUCCESS ===")

        AdvertisementPacket(
            packetVersion = packetVersion,
            rssiDelta = rssiDelta,
            terminalCapabilities = terminalCapabilities,
            operationCounter = operationCounter,
            qrcId = qrcId,
        )
    }
}