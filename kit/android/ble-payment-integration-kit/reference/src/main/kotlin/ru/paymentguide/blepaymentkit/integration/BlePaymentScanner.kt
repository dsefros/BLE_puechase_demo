package ru.paymentguide.blepaymentkit.integration

import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import ru.paymentguide.blepaymentkit.BlePacketProcessingResult
import ru.paymentguide.blepaymentkit.BlePaymentKit

class BlePaymentScanner(
    private val sdk: BlePaymentKit,
    private val mapper: BlePaymentScanMapper = BlePaymentScanMapper(),
    private val onResult: (BlePacketProcessingResult) -> Unit,
) : ScanCallback() {
    override fun onScanResult(callbackType: Int, result: ScanResult) {
        val mapped = mapper.map(result)
        if (mapped is BlePaymentScanResult.Mapped) {
            onResult(sdk.process(mapped.input))
        }
    }
}
