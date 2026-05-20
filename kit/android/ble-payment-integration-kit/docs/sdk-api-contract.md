# SDK API contract

## Config (`BlePaymentConfig`)

| Field | Type | Default |
|---|---|---|
| `serviceUuid` | `String` | `0000534B-0000-1000-8000-00805F9B34FB` |
| `supportedPacketVersion` | `Int` | `1` |
| `requiredCapabilityMask` | `Int` | `0x80` |
| `manufacturerId` | `Int` | `0xF001` |
| `rssiThreshold` | `Int` | `-70` |
| `defaultMerchantName` | `String` | `Терминал Волна` |
| `qrLinkPrefix` | `String` | `https://qr.nspk.ru` |

## Input (`BlePacketInput`)

| Field | Type | Meaning |
|---|---|---|
| `advertisementData` | `ByteArray` | Required advertisement/service payload bytes |
| `scanResponseData` | `ByteArray?` | Manufacturer payload bytes (no manufacturer ID bytes) |
| `manufacturerId` | `Int?` | Manufacturer ID (if null, config default is used) |
| `rssi` | `Int` | RSSI at scan time |
| `timestamp` | `Instant` | Host-provided event time |
| `deviceIdentifier` | `String` | Device identity (e.g., MAC address string) |
| `localName` | `String?` | Optional local name |

## Output (`BlePacketProcessingResult`)

- `Accepted(candidate: BlePaymentCandidate)`
- `Rejected(reason: BlePacketRejectReason)`

`BlePaymentCandidate` fields: `qrcId`, `qrLink`, `amountMinor`, `merchantName`, `packetVersion`, `operationCounter`, `rssi`, `finalRssi`, `rssiDelta`, `deviceIdentifier`, `localName`, `timestamp`.

## Reject reasons enum

`invalidPrefix`, `malformedPayload`, `missingRequiredField`, `weakRSSI`, `expiredPacket`, `unsupportedVersion`, `duplicatePacket`, `signalBelowThreshold`, `packetTooShort`, `invalidQrcId`, `unknown`.
