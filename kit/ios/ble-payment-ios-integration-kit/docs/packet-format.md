# Packet Format (Current Implementation)

## Advertisement payload (service data for configured service UUID)
- Byte 0: high 3 bits packet version, low 5 bits signed RSSI delta.
- Byte 1: capabilities bitmask (must satisfy required mask).
- Byte 2: operation counter.
- Byte 3...N: QRC payload bytes; converted to base36 `qrcId`.

## Scan response manufacturer payload
CoreBluetooth manufacturer data includes a 2-byte little-endian manufacturer/company ID prefix.

Split before SDK input mapping:
- Prefix bytes 0..1 => `manufacturerId`.
- Remaining bytes => `scanResponseData` body.

The `scanResponseData` body format is:
- Bytes 0...3: amount (`UInt32` big-endian, must be > 0).
- Bytes 4...N: merchant name in Windows-1251; trimmed; fallback to `defaultMerchantName` if empty.

`qrcId` from advertisement payload is used to build `qrLink` as:
`<qrLinkPrefix without trailing slash>/<qrcId>`.
