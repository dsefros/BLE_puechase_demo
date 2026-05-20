# iOS CoreBluetooth Scanning

Host app responsibilities:
- Own `CBCentralManager` lifecycle and delegate.
- Check Bluetooth readiness/authorization.
- Start and stop scan.
- Read `didDiscover` fields: `advertisementData`, `RSSI`, `peripheral.identifier`.

Key advertisement keys:
- `CBAdvertisementDataServiceDataKey`
- `CBAdvertisementDataManufacturerDataKey`
- `CBAdvertisementDataLocalNameKey`

Practical integration rules:
- Filter/select service data by configured `BlePaymentConfig.serviceUUID`.
- Do not rely on first dictionary entry from service data.
- Split manufacturer bytes into `manufacturerId` (first two little-endian bytes) and body payload.

This kit provides mapping/reference scanner code; it is intentionally lightweight and not a full permission manager.
