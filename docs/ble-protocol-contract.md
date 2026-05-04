# BLE Protocol Contract (Android ↔ future iOS)

## 1) Purpose

This document is the shared BLE behavior contract for the current Android implementation and future iOS implementations. It specifies protocol behavior that both platforms must follow for scan-time advertisement parsing and candidate assembly.

Primary Android sources for this contract:

- `app/src/main/java/com/example/volnabledemo/data/ble/AdvertisementPacketParser.kt`
- `app/src/main/java/com/example/volnabledemo/data/ble/ScanResponseParser.kt`
- `app/src/main/java/com/example/volnabledemo/data/ble/VolnaQrcIdConverter.kt`
- `app/src/main/java/com/example/volnabledemo/data/ble/SignalStrengthValidator.kt`
- `app/src/main/java/com/example/volnabledemo/data/ble/VolnaCandidateAssembler.kt`
- `app/src/main/java/com/example/volnabledemo/data/ble/AndroidBleScanner.kt`
- `app/src/main/java/com/example/volnabledemo/presentation/PaymentViewModel.kt`
- `app/src/main/java/com/example/volnabledemo/presentation/PaymentFlowState.kt`
- `app/src/main/java/com/example/volnabledemo/domain/model/Models.kt`
- `app/build.gradle.kts`
- `app/src/main/AndroidManifest.xml`

## 2) Current BLE mode

Based on current repository code, the app is currently:

- **Scan-only**: yes (BLE scan loop receives advertisements and parses advertisement data).
- **Scan + connect**: **not found in repository**.
- **GATT read/write/notify**: **not found in repository**.
- **Pairing/bonding flow**: **not found in repository**.

The scanner uses Android LE scan callbacks and processes advertisement fields only (`app/src/main/java/com/example/volnabledemo/data/ble/AndroidBleScanner.kt`).

## 3) Discovery inputs

Current discovery/parsing inputs (from `app/src/main/java/com/example/volnabledemo/domain/model/Models.kt` and `app/src/main/java/com/example/volnabledemo/data/ble/AndroidBleScanner.kt`):

- **Service UUID**: `0000534B-0000-1000-8000-00805F9B34FB`.
- **Manufacturer ID**: `0xF001`.
- **Advertised name usage**: device name is logged for diagnostics only; no acceptance logic based on name was found.
- **Service data usage**: required for parsing packet version, RSSI delta, capabilities, operation counter, and QRC payload.
- **Manufacturer data usage**: required for amount and merchant parsing.
- **RSSI usage**: scan RSSI combined with service-data RSSI delta for threshold validation.

## 4) Service data format

Current parser behavior (`app/src/main/java/com/example/volnabledemo/data/ble/AdvertisementPacketParser.kt`) is:

- Minimum payload: at least 3 bytes.
- **Byte 0**: packed field `versionAndDelta`.
  - Packet version = upper 3 bits (`bits 7..5`).
  - RSSI delta = lower 5 bits (`bits 4..0`) interpreted as signed 5-bit value.
- **Byte 1**: terminal capabilities.
  - Required capability mask is `0x80` (`requiredOnlineC2bCapabilityMask` from `app/src/main/java/com/example/volnabledemo/domain/model/Models.kt`), enforced by bitwise check.
- **Byte 2**: operation counter (`UInt8` semantics via `and 0xFF`).
- **Bytes 3..end**: QRC ID binary payload; passed to converter and rendered as uppercase Base36 string.

Supported packet version is currently `0b001` (`app/src/main/java/com/example/volnabledemo/domain/model/Models.kt`).

## 5) Manufacturer data format

Current parser behavior (`app/src/main/java/com/example/volnabledemo/data/ble/ScanResponseParser.kt`) is:

- Manufacturer ID must equal `0xF001`.
- Minimum manufacturer payload length: **4 bytes**.
- First 4 bytes parsed as unsigned big-endian 32-bit integer (`amountMinor`).
- `amountMinor` must be `> 0`.
- Remaining bytes decoded as CP1251 (`windows-1251`) merchant string.
- Merchant string is right-trimmed for `\0` and whitespace; blank merchant falls back to `"Терминал Волна"`.

## 6) QRC ID conversion

Current conversion behavior (`app/src/main/java/com/example/volnabledemo/data/ble/VolnaQrcIdConverter.kt`):

- Binary payload is interpreted as an **unsigned big-endian integer** (`BigInteger(1, payload)`).
- Integer is converted to Base36 using alphabet `0-9A-Z` (uppercase output).
- Empty payload returns empty string.
- All-zero payload returns `"0"`.
- No forced fixed-width Base36 output padding is applied.

Length notes (from `app/src/main/java/com/example/volnabledemo/domain/model/Models.kt` and `app/src/main/java/com/example/volnabledemo/data/ble/AdvertisementPacketParser.kt`):

- `VolnaContract.qrcIdBytesLength = 21` exists as a contract constant.
- Parser accepts `bytes[3..end]` without enforcing fixed length.
- Therefore fixed-length requirement at runtime is **not fully enforced in parser** (only partially implied by constants/tests).

## 7) RSSI validation

Current behavior (`app/src/main/java/com/example/volnabledemo/data/ble/SignalStrengthValidator.kt`, `app/src/main/java/com/example/volnabledemo/data/ble/VolnaCandidateAssembler.kt`):

- `finalRssi = rssi - rssiDelta`.
- Candidate is valid iff `finalRssi >= threshold`.
- Default threshold is `-70` (`BuildConfig.RSSI_THRESHOLD`).
- Threshold value source is Gradle `buildConfigField("int", "RSSI_THRESHOLD", "-70")` in `app/build.gradle.kts` and injected in `app/src/main/java/com/example/volnabledemo/app/di/AppContainer.kt`.

## 8) Candidate acceptance flow

Observed flow in scanner and ViewModel (`app/src/main/java/com/example/volnabledemo/data/ble/AndroidBleScanner.kt`, `app/src/main/java/com/example/volnabledemo/presentation/PaymentViewModel.kt`):

`scan result`
→ presence check for serviceData + manufacturerData
→ parse service data
→ parse manufacturer data
→ validate capability (inside service parser)
→ convert QRC ID (inside service parser)
→ validate signal (candidate assembler)
→ assemble candidate
→ emit `Outcome.Success(ScanResult(candidate))`
→ ViewModel transitions to `PaymentFlowState.ReadyForConfirmation`

Rejection/continue behavior (same files as above):

- Invalid packet/parse failures are ignored (no terminal failure emitted for each bad packet).
- Weak RSSI candidate assembly failure is ignored/rejected and scanning continues.
- Missing service/manufacturer data for a device is ignored.
- Scan continues until success, scan failure callback, or timeout.

## 9) Timeout and retry behavior

- Scan timeout is `BuildConfig.SCAN_TIMEOUT_MS`, default `10000L` (10 seconds) from `app/build.gradle.kts`.
- Timeout handling is inside `app/src/main/java/com/example/volnabledemo/data/ble/AndroidBleScanner.kt` (`delay(scanTimeoutMs)` then `Failure.ScanFailure.Timeout`).
- Retry/restart behavior is at ViewModel/UI level, not inside scanner protocol parser (`app/src/main/java/com/example/volnabledemo/presentation/PaymentViewModel.kt`):
  - manual `startScan()` restarts scan;
  - auto-scan can trigger scan on app start and after reset/success when enabled.
- No low-level scanner-internal retry/backoff strategy was found.

## 10) Events and states

BLE-level outcomes mapped to app-level states (`app/src/main/java/com/example/volnabledemo/presentation/PaymentViewModel.kt`, `app/src/main/java/com/example/volnabledemo/presentation/PaymentFlowState.kt`):

- **Discovered candidate** → `Outcome.Success` from scanner → `PaymentFlowState.ReadyForConfirmation`.
- **Rejected candidate** (invalid packet, unsupported capability, bad manufacturer payload, weak RSSI) → ignored in scanner loop (state remains scanning until terminal event).
- **Scan timeout** → `Failure.ScanFailure.Timeout` → `PaymentFlowState.BlockingError`.
- **Blocking prerequisite error** (BLE unsupported / Bluetooth disabled / permissions / no internet) → `PaymentFlowState.BlockingError` before scan phase.
- **Ready for confirmation** → `PaymentFlowState.ReadyForConfirmation(candidate)`.
- **Submit/success/error**:
  - submit: `PaymentFlowState.SubmittingPayment(candidate)`
  - success: `PaymentFlowState.PaymentSuccess(candidate)`
  - error: `PaymentFlowState.PaymentError(...)`

## 11) Platform-specific notes

### Android-specific implementation details

- Uses `BluetoothLeScanner` callbacks and `ScanRecord` accessors (`app/src/main/java/com/example/volnabledemo/data/ble/AndroidBleScanner.kt`).
- Current controller starts scan **without BLE scan filters** (`emptyList<ScanFilter>()`) and performs filtering in app logic (`app/src/main/java/com/example/volnabledemo/data/ble/AndroidBleScanner.kt`).
- Uses `ParcelUuid(VolnaContract.serviceUuid)` + manufacturer ID accessors for advertisement extraction (`app/src/main/java/com/example/volnabledemo/data/ble/AndroidBleScanner.kt`).
- BLE-related permissions/features are declared in `app/src/main/AndroidManifest.xml`.

### Future iOS implementation notes

- iOS should reproduce protocol behavior via **CoreBluetooth scanning + advertisement parsing**.
- iOS should match protocol semantics (field extraction/validation/conversion), not Android API classes.
- Do not treat Android scanner API specifics as protocol requirements.

### Initial iOS MVP scope

- Initial iOS MVP should target **foreground-only, scan-only parity** with the current Android implementation.
- **Background BLE is not part of the initial MVP**.
- Background BLE may be evaluated later in a separate feasibility spike.
- **No GATT implementation is required** unless future protocol requirements change.

## 12) Unknowns / not found in repository

- GATT service/characteristic UUIDs: **not found in repository**.
- Tag lost semantics: **not found in repository**.
- Background BLE requirement/specification: **not found in repository**.
- Formal external BLE protocol specification document: **not found in repository**.
- Strict fixed-width QRC ID output rules: **not found in repository**.
- Duplicate candidate selection/dedup policy: **not found in repository**.

## 13) Acceptance checklist for future iOS implementation

Future iOS PR should verify all items:

- [ ] Uses same service UUID: `0000534B-0000-1000-8000-00805F9B34FB`.
- [ ] Uses same manufacturer ID: `0xF001`.
- [ ] Implements same service data parsing (version + signed 5-bit delta + capability + counter + QRC payload).
- [ ] Enforces required capability mask `0x80`.
- [ ] Implements same manufacturer data parsing (unsigned big-endian amountMinor + CP1251 merchant bytes).
- [ ] Uses CP1251 decoding behavior equivalent to current Android logic.
- [ ] Implements same Base36 uppercase QRC conversion semantics.
- [ ] Uses same RSSI formula `finalRssi = rssi - rssiDelta`.
- [ ] Uses same default threshold semantics (`-70` unless app configuration changes).
- [ ] Applies timeout semantics equivalent to scanner timeout behavior where applicable.
- [ ] Initial release scope is foreground scan-only parity; background BLE and GATT are out of MVP scope unless explicitly added in a future protocol revision.
- [ ] Documents any intentional deviations from this contract.
