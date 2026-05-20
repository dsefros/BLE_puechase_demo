# SDK API Contract

## Config (`BlePaymentConfig` defaults)
- `serviceUUID`: `0000534B-0000-1000-8000-00805F9B34FB`
- `supportedPacketVersion`: `0b001`
- `requiredCapabilityMask`: `0x80`
- `manufacturerId`: `0xF001`
- `rssiThreshold`: `-70`
- `defaultMerchantName`: `Терминал Волна`
- `qrLinkPrefix`: `https://qr.nspk.ru`

## Input (`BlePacketInput`)
`advertisementData`, `scanResponseData`, `manufacturerId`, `rssi`, `timestamp`, `deviceIdentifier`, `localName`.

## Output
- `BlePacketProcessingResult.accepted(BlePaymentCandidate)`
- `BlePacketProcessingResult.rejected(BlePacketRejectReason)`
