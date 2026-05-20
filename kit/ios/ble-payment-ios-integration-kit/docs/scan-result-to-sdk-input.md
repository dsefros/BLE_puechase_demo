# Scan Result to SDK Input

`BlePaymentKit` expects:
- `advertisementData`: service payload bytes.
- `scanResponseData`: manufacturer payload bytes **without** manufacturer ID.
- `manufacturerId`: separate numeric manufacturer ID.

## Service data selection rule

CoreBluetooth `CBAdvertisementDataServiceDataKey` may include multiple service UUID entries.

Use the SDK config service UUID as the lookup key:
- build `CBUUID(string: config.serviceUUID)`;
- read exactly `serviceDataMap[expectedServiceUUID]`;
- do **not** use `serviceDataMap.values.first`.

## Manufacturer data split rule

CoreBluetooth `CBAdvertisementDataManufacturerDataKey` bytes are split as:
- bytes 0..1 (little-endian): `manufacturerId`
- bytes 2..N: `scanResponseData`

```swift
let config = BlePaymentConfig.default
let mapper = BlePaymentAdvertisementMapper(config: config)

if let input = mapper.map(
    advertisementData: advertisementData,
    rssi: RSSI.intValue,
    peripheralIdentifier: peripheral.identifier.uuidString
) {
    let result = BlePaymentKit(config: config).process(input: input)
}
```
