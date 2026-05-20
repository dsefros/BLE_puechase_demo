// Example snippet (not a standalone file): connect BlePaymentScanner to BluetoothLeScanner.
val sdk = BlePaymentKit(BlePaymentConfig.default())
val callback = BlePaymentScanner(sdk = sdk) { result ->
    when (result) {
        is BlePacketProcessingResult.Accepted -> println(result.candidate)
        is BlePacketProcessingResult.Rejected -> println(result.reason)
    }
}
// bluetoothLeScanner.startScan(callback)
