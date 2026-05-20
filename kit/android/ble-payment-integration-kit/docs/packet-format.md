# Packet format (current implementation)

## Advertisement/service payload (`advertisementData`)

| Offset | Size | Description |
|---|---:|---|
| 0 | 1 | 3-bit version (bits 7..5) + signed 5-bit RSSI delta (bits 4..0) |
| 1 | 1 | Terminal capability bitmask (must include required mask) |
| 2 | 1 | Operation counter |
| 3..N | N-3 | QRC payload bytes (unsigned big-endian -> base36 `qrcId`) |

## Manufacturer payload (`scanResponseData`)

| Offset | Size | Description |
|---|---:|---|
| 0..3 | 4 | Amount in minor units, unsigned big-endian UInt32, must be `> 0` |
| 4..N | N-4 | Merchant name in `windows-1251`; trailing NUL/whitespace trimmed |

## Worked example from tests

- Advertisement hex: `2280010100`
- Manufacturer payload hex: `0000303944656D6F204D65726368616E74`
- Input RSSI: `-60`

Decoded result:
- `packetVersion=1`
- `rssiDelta=2`
- `finalRssi=-62`
- `qrcId="74"`
- `amountMinor=12345`
- `merchantName="Demo Merchant"`
