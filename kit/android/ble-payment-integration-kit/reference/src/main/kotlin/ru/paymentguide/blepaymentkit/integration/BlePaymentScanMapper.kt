package ru.paymentguide.blepaymentkit.integration

import android.bluetooth.le.ScanResult
import android.os.ParcelUuid
import ru.paymentguide.blepaymentkit.BlePacketInput
import ru.paymentguide.blepaymentkit.BlePaymentConfig
import java.time.Instant

class BlePaymentScanMapper(
    private val config: BlePaymentConfig = BlePaymentConfig.default(),
    private val now: () -> Instant = { Instant.now() },
) {
    private val serviceUuid = ParcelUuid.fromString(config.serviceUuid)

    fun map(scanResult: ScanResult): BlePaymentScanResult {
        val record = scanResult.scanRecord ?: return BlePaymentScanResult.Ignored
        val advertisement = record.getServiceData(serviceUuid) ?: return BlePaymentScanResult.Ignored
        val manufacturerPayload = record.getManufacturerSpecificData(config.manufacturerId)
        val input = BlePacketInput(
            advertisementData = advertisement,
            scanResponseData = manufacturerPayload,
            manufacturerId = config.manufacturerId,
            rssi = scanResult.rssi,
            // ScanResult.timestampNanos is monotonic elapsed-realtime, not wall-clock UNIX time.
            timestamp = now(),
            deviceIdentifier = scanResult.device.address ?: "unknown",
            localName = record.deviceName,
        )
        return BlePaymentScanResult.Mapped(input)
    }
}
