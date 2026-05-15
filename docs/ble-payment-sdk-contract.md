# BLE Payment SDK Contract

## Purpose and scope

This document defines a shared cross-platform contract for standalone iOS and Android BLE payment packet processing libraries. The contract is grounded in the existing repository implementation, especially:

- `ios/BLEApp/BLEApp/BLE/Config/BleConfig.swift`
- `ios/BLEApp/BLEApp/BLE/Parser/AdvertisementPacketParser.swift`
- `ios/BLEApp/BLEApp/BLE/Parser/ScanResponseParser.swift`
- `ios/BLEApp/BLEApp/BLE/Parser/VolnaQrcIdConverter.swift`
- `ios/BLEApp/BLEApp/BLE/Parser/VolnaCandidateAssembler.swift`
- `ios/BLEApp/BLEApp/BLE/Scanner/CoreBluetoothBleScanner.swift`
- `ios/BLEApp/BLEApp/UI/Home/HomeViewModel.swift`
- `app/src/main/java/com/example/volnabledemo/data/ble/AdvertisementPacketParser.kt`
- `app/src/main/java/com/example/volnabledemo/data/ble/ScanResponseParser.kt`
- `app/src/main/java/com/example/volnabledemo/data/ble/VolnaQrcIdConverter.kt`
- `app/src/main/java/com/example/volnabledemo/data/ble/VolnaCandidateAssembler.kt`
- `app/src/main/java/com/example/volnabledemo/data/ble/SignalStrengthValidator.kt`
- `app/src/main/java/com/example/volnabledemo/domain/model/Models.kt`

The SDKs are intentionally limited to deterministic packet processing:

`BLE packet input → parsing → payload extraction → validation → candidate formation → reject reason`

The SDKs **must not** perform BLE scanning lifecycle management, Bluetooth permission handling, UI rendering, payment creation/submission, backend networking, payment status polling, app navigation, or app-specific logging.

## Actual packet input model

A host application supplies platform-neutral packet data after it receives a BLE scan result. Existing BLEApp scanner code extracts Volna service data and manufacturer data from platform BLE APIs before parsing.

| Field | Type | Required | Existing-app source / meaning |
| --- | --- | --- | --- |
| `advertisementData` | bytes | yes | Volna service data for service UUID `0000534B-0000-1000-8000-00805F9B34FB`. Android obtains it from `ScanRecord.getServiceData(...)`; iOS obtains it from `CBAdvertisementDataServiceDataKey`. |
| `scanResponseData` | bytes, nullable | yes for candidate formation | Normalized manufacturer payload for manufacturer ID `0xF001`, with any platform-specific company identifier bytes already removed. Existing Android receives this normalized payload from `getManufacturerSpecificData(0xF001)`. Existing iOS splits raw CoreBluetooth manufacturer data because CoreBluetooth includes the little-endian company identifier in the raw data. |
| `manufacturerId` | integer, nullable | no | Manufacturer ID associated with `scanResponseData`. If omitted, SDKs assume the configured manufacturer ID `0xF001`. |
| `rssi` | integer dBm | yes | Raw scan RSSI from the platform scanner. |
| `timestamp` | instant/date | metadata | Existing BLEApp stores scan event time but does not use it for packet expiry validation. |
| `deviceIdentifier` | string | metadata | Host-provided peripheral/device identifier. Existing iOS candidate stores the peripheral UUID string. |
| `localName` | string, nullable | metadata | Host-provided peripheral name. Existing code does not use local name for packet acceptance. |

Public SDK APIs should use plain values such as `Data`/`ByteArray`, `String`, `Int`, `UInt16`/`Int`, and `Date`/`Instant`-like values. Public APIs should avoid platform Bluetooth framework types where practical.

## Output model: `BlePacketProcessingResult`

Processing returns one of two outcomes:

- `accepted(candidate)`: the packet parsed and passed current repository validation.
- `rejected(reason)`: the packet was ignored for a deterministic SDK reason mapped from current parser/validator behavior.

`BlePaymentCandidate` is **not a created payment**. It is only an intermediate object meaning: **“a BLE packet was detected and accepted as a possible payment candidate.”** The host application decides what to do next, including whether to show UI, submit payment data, call a backend, poll status, or ignore the candidate.

## Core models

### `BlePaymentCandidate`

Fields aligned with existing `PaymentCandidate` / `VolnaCandidate` data:

- `qrcId`: QRC identifier decoded from the service-data QRC payload.
- `qrLink`: QR link formed by appending `qrcId` to the configured QR prefix, matching existing Android candidate assembly.
- `amountMinor`: amount in minor currency units from manufacturer payload.
- `merchantName`: merchant display name from manufacturer payload.
- `packetVersion`: parsed packet version.
- `operationCounter`: parsed operation counter.
- `rssi`: raw observed RSSI.
- `finalRssi`: `rssi - rssiDelta`.
- `rssiDelta`: signed RSSI delta from service data.
- `deviceIdentifier`: host-provided device identifier.
- `localName`: host-provided local name, nullable.
- `timestamp`: packet observation timestamp, metadata only.

### `BlePacketRejectReason`

These names remain semantically aligned across platforms. Not every reason is currently emitted by existing BLEApp logic.

- `invalidPrefix`: reserved for a future protocol prefix rule. **Current BLEApp has no prefix check and SDKs must not invent one.**
- `malformedPayload`: manufacturer payload is malformed, too short, or has a non-positive amount.
- `missingRequiredField`: required service data, manufacturer payload, or required capability is missing.
- `weakRSSI`: alias-level semantic reason for weak signal; current SDKs emit `signalBelowThreshold` for exact repository parity.
- `expiredPacket`: reserved for future host/SDK freshness policy. **Current BLEApp does not reject packets by timestamp.**
- `unsupportedVersion`: service-data packet version is not `1`.
- `duplicatePacket`: reserved for future host/SDK duplicate policy. **Current BLEApp does not perform SDK-level duplicate rejection.**
- `signalBelowThreshold`: `rssi - rssiDelta` is below configured threshold.
- `packetTooShort`: service data has fewer than 3 bytes.
- `invalidQrcId`: reserved for future QRC validation. Current parser permits an empty payload and returns an empty QRC ID.
- `unknown`: fallback for errors that do not map cleanly to a known reason.

## Configuration constants

Defaults match existing BLEApp constants:

- `serviceUUID`: `0000534B-0000-1000-8000-00805F9B34FB`.
- `manufacturerId`: `0xF001`.
- `supportedPacketVersion`: `1` (`0b001`).
- `requiredCapabilityMask`: `0x80`.
- `rssiThreshold`: `-70`.
- `defaultMerchantName`: `Терминал Волна`.
- `qrLinkPrefix`: `https://qr.nspk.ru`.

The existing app has a scan timeout, but that belongs to scanning lifecycle and is outside SDK packet processing.

## Proven packet parsing contract

The following rules are proven by existing BLEApp code and tests:

- Service data minimum length is 3 bytes.
- Service-data byte 0 packs packet version in the upper 3 bits and signed RSSI delta in the lower 5 bits.
- Packet version must equal `1`.
- The lower 5 RSSI-delta bits are interpreted as signed 5-bit two's complement (`0...15`, `-16...-1`).
- Service-data byte 1 stores terminal capabilities. The required capability bit is `0x80`.
- Service-data byte 2 stores operation counter as an unsigned byte.
- Service-data bytes 3 through end store the binary QRC ID payload.
- QRC ID bytes are interpreted as an unsigned big-endian integer and rendered as uppercase Base36. Empty payload returns an empty string; all-zero payload returns `0`.
- `qrcIdBytesLength = 21` exists in Android constants/test helpers, but current parsers do **not** enforce a fixed QRC payload length.
- Manufacturer ID must be `0xF001`.
- Manufacturer payload minimum length is 4 bytes.
- The first 4 manufacturer payload bytes are unsigned big-endian `amountMinor`.
- `amountMinor` must be greater than zero.
- Remaining manufacturer payload bytes are decoded as Windows-1251 merchant text, then trailing NUL/whitespace is trimmed.
- Blank merchant text falls back to `Терминал Волна`.
- Signal validation uses `finalRssi = rssi - rssiDelta`; the candidate is accepted only when `finalRssi >= rssiThreshold`.

## Explicitly unsupported / not implemented by current BLEApp packet processing

The current repository does **not** define or enforce:

- Any advertisement prefix byte or prefix string rule.
- Packet expiry based on the packet timestamp.
- SDK-level duplicate packet rejection.
- Strict fixed-length QRC payload rejection.
- Payment creation, backend calls, payment status polling, navigation, UI, BLE permissions, or scanner lifecycle inside packet parser/SDK code.

Test vectors for prefix, duplicate, or expiry scenarios are therefore marked as synthetic compatibility placeholders and must not be interpreted as real protocol examples.

## Public API examples

### Swift

```swift
let sdk = BlePaymentKit(config: .default)
let result = sdk.process(input: input)

switch result {
case .accepted(let candidate):
    // Host app decides what to do with the candidate.
    _ = candidate
case .rejected(let reason):
    // Host app may ignore or log the deterministic reason.
    _ = reason
}
```

### Kotlin

```kotlin
val sdk = BlePaymentKit(config = BlePaymentConfig.default())
val result = sdk.process(input)

when (result) {
    is BlePacketProcessingResult.Accepted -> {
        val candidate = result.candidate
    }
    is BlePacketProcessingResult.Rejected -> {
        val reason = result.reason
    }
}
```

## Validation commands

From the repository root:

```bash
swift test --package-path ios/BlePaymentKit
```

For Android:

```bash
cd android/ble-payment-kit && gradle test
```

Android validation may require JDK 17. The current container's JDK `25.0.2` causes Gradle/Kotlin tooling to fail before compilation, so Android tests should be run in a JDK 17 environment.
