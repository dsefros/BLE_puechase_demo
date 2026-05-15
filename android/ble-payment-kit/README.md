# BlePaymentKit Android/Kotlin

Standalone Kotlin library skeleton for deterministic BLE payment packet processing. It mirrors the packet-processing facts already present in this repository and does not scan for BLE devices, request permissions, render UI, submit payments, call backends, poll payment status, or integrate with an app.

Package namespace: `ru.paymentguide.blepaymentkit`.

Public API shape:

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

The API uses plain Kotlin/JVM values (`ByteArray`, `String`, `Int`, `Instant`) rather than Android Bluetooth framework scan types. `scanResponseData` is the normalized manufacturer payload for manufacturer ID `0xF001`, matching Android `ScanRecord.getManufacturerSpecificData(0xF001)` output.

## Validation

Run Android library tests from the repository root with:

```bash
cd android/ble-payment-kit && gradle test
```

Android validation may require JDK 17. In the current container, Gradle/Kotlin tooling fails before compilation with JDK `25.0.2`, so run this command in a JDK 17 environment if you hit that version-parsing failure.

The iOS companion package can be validated from the repository root with:

```bash
swift test --package-path ios/BlePaymentKit
```
