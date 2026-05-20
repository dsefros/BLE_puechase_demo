# Quick start

## 1) Create SDK + mapper

```kotlin
val config = BlePaymentConfig.default()
val sdk = BlePaymentKit(config)
val mapper = BlePaymentScanMapper(config)
```

## 2) Process Android scan callbacks

```kotlin
override fun onScanResult(callbackType: Int, result: ScanResult) {
    when (val mapped = mapper.map(result)) {
        is BlePaymentScanResult.Ignored -> Unit
        is BlePaymentScanResult.Mapped -> {
            when (val processed = sdk.process(mapped.input)) {
                is BlePacketProcessingResult.Accepted -> {
                    // Use processed.candidate, then stop or continue scanning per app policy.
                }
                is BlePacketProcessingResult.Rejected -> {
                    // Optional debug logging: processed.reason
                }
            }
        }
    }
}
```

## 3) Optional reference callback

Use `reference/.../BlePaymentScanner.kt` if you want a minimal wrapper around this mapping + processing flow.
