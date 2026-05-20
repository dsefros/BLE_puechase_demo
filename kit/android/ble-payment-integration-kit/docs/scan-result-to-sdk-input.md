# Mapping `ScanResult` to `BlePacketInput`

`BlePaymentScanMapper.map(...)` returns:
- `BlePaymentScanResult.Ignored` if required BLE record parts are missing,
- `BlePaymentScanResult.Mapped(input)` when enough data exists for SDK processing.

```kotlin
class BlePaymentScanMapper(private val config: BlePaymentConfig = BlePaymentConfig.default()) {
    private val serviceUuid = ParcelUuid.fromString(config.serviceUuid)

    fun map(scanResult: ScanResult): BlePaymentScanResult {
        val record = scanResult.scanRecord ?: return BlePaymentScanResult.Ignored
        val advertisement = record.getServiceData(serviceUuid) ?: return BlePaymentScanResult.Ignored
        val manufacturerPayload = record.getManufacturerSpecificData(config.manufacturerId)

        return BlePaymentScanResult.Mapped(
            BlePacketInput(
                advertisementData = advertisement,
                scanResponseData = manufacturerPayload,
                manufacturerId = config.manufacturerId,
                rssi = scanResult.rssi,
                timestamp = Instant.now(),
                deviceIdentifier = scanResult.device.address ?: "unknown",
                localName = record.deviceName,
            ),
        )
    }
}
```

Notes:
- `scanResponseData` is payload bytes **without** manufacturer ID bytes (Android already strips them for `getManufacturerSpecificData(id)`).
- `ScanResult.timestampNanos` is monotonic elapsed-realtime, not wall-clock UNIX time; use `Instant.now()` (or injected clock) for SDK timestamp field.
