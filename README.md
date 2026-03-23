# Volna BLE Demo Android App

Android demo application for the **Volna C2B QR-like BLE scenario**. This repository does **not** implement tokenized card flows, APDU transport, EMV logic, or production banking features. The app is intentionally limited to a foreground-only happy path: scan BLE, reconstruct Volna payment data, show a confirmation screen, send one HTTPS POST, and display success or error.

## Repository state and scope

The repository contains a single Android module `app` implemented with Kotlin + Jetpack Compose. The code is organized into `presentation`, `domain`, `data`, and `platform` layers so the demo remains small but still cleanly extensible.

## What the app does

1. Shows a home screen with a single CTA: **Start BLE scanning**.
2. Checks BLE support, Bluetooth state, runtime permissions, and internet connectivity.
3. Starts BLE scan filtered by Volna Service UUID `0000534B-0000-1000-8000-00805F9B34FB`.
4. Parses Advertisement / Service Data:
   - first byte: **3-bit packet version** + **signed 5-bit RSSI Delta**
   - second byte: terminal capabilities, where **bit 7 (`0x80`) means SBP C2B online supported**
   - third byte: operation counter
   - next 21 bytes: binary QRC ID payload
5. Parses Scan Response / Manufacturer Data for manufacturer `0xF001`:
   - 4-byte amount in minimal currency units, unsigned big-endian
   - up to 23 bytes merchant name / cash desk name in CP1251
6. Computes `RSSI Final = RSSI - RSSI Delta` and applies the app threshold.
7. Stops scanning after the first valid candidate.
8. Builds `https://qr.nspk.ru/{QRC_ID}`.
9. Shows payment confirmation.
10. Sends exactly one HTTPS POST with a 10-second timeout and no automatic retries.
11. Shows success or error, then returns to home on the success path.
12. If BLE permissions are denied, shows an explicit blocking error state instead of silently resetting to idle, using Android-version-appropriate wording.

## QRC ID reconstruction status

The packet contains **21 bytes of binary QRC ID form** and the app must reconstruct the original Base36 QRC ID string.

What I was able to verify in this environment:
- the repository itself does **not** contain local PDFs, pcaps, or BLE sample captures that prove the exact normalization rule;
- no directly verifiable binary/string example from the Volna C2B materials was available in the repository workspace during this task;
- the task context indicates that at least one spec example uses a **32-character QRC ID string**, which means the previous hardcoded **33-character left-padding** rule was too strong and potentially misleading.

Because of that, the converter now uses the least assertive behavior that is still deterministic:

- interpret the 21-byte field as an **unsigned big-endian integer**;
- convert it to **uppercase Base36**;
- **do not force fixed-width padding**.

This means one ambiguity remains: if the formal Volna spec requires restoring leading Base36 zeroes to a fixed width, that exact width could not be proven here from concrete evidence. The behavior is isolated in `VolnaQrcIdConverter`, so changing the normalization rule later is a local change. No fixed-width Base36 length is currently assumed in the contract layer.

## Build

```bash
./gradlew test
./gradlew assembleDebug
```

This repository includes a normal Gradle wrapper layout (`gradlew`, `gradlew.bat`, `gradle/wrapper/*`) suitable for Android Studio / standard Gradle usage.

## Run

1. Open the project in Android Studio.
2. Ensure a JDK compatible with the Android Gradle Plugin is configured in the IDE.
3. Run the `app` configuration on a BLE-capable Android device.
4. Grant the required runtime permissions. If you deny them, the app shows an explicit error state and lets you return and retry.
5. Tap **Start BLE scanning**.

## Required permissions

- `BLUETOOTH_SCAN`
- `BLUETOOTH_CONNECT`
- `ACCESS_FINE_LOCATION` on Android 11 and lower
- `INTERNET`
- `ACCESS_NETWORK_STATE`

## Where to change demo config

`app/build.gradle.kts` exposes the local demo config via `BuildConfig`:

- `PAYMENT_BASE_URL`
- `SCAN_TIMEOUT_MS`
- `RSSI_THRESHOLD`
- `SBP_PREFIX`

## Architecture summary

- `presentation`: Compose screens + `PaymentViewModel` state machine
- `domain`: models, repository interfaces, use cases
- `data/ble`: parsers, QRC ID converter, signal validator, candidate assembler, BLE scanner abstraction
- `data/network`: Retrofit API and DTOs
- `data/repository`: payment repository implementation
- `platform`: Android-specific prerequisite and permission/network checks

## Demo limitations

- Foreground-only happy path
- No pairing/bonding, background scanning, reconnect logic, history, auth, analytics, or multi-terminal selection UI
- No tokenized card, GATT payment data transport, APDU, or EMV
- Host API remains demo-friendly and easy to replace once the real contract is finalized
