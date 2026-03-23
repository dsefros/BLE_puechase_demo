package com.example.volnabledemo

import com.example.volnabledemo.data.ble.AdvertisementPacketParser
import com.example.volnabledemo.data.ble.AndroidBleScanner
import com.example.volnabledemo.data.ble.ScanController
import com.example.volnabledemo.data.ble.ScanControllerCallback
import com.example.volnabledemo.data.ble.ScanResponseParser
import com.example.volnabledemo.data.ble.VolnaCandidateAssembler
import com.example.volnabledemo.domain.error.Failure
import com.example.volnabledemo.domain.model.Outcome
import com.google.common.truth.Truth.assertThat
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class AndroidBleScannerTest {
    @Test
    fun `timeout stops scan exactly once`() = runTest {
        val controller = FakeScanController()
        val scanner = createScanner(controller)

        val outcome = scanner.scanForCandidate().first()

        assertThat(outcome).isEqualTo(Outcome.FailureResult(Failure.ScanFailure.Timeout))
        assertThat(controller.stopCalls).isEqualTo(1)
    }

    @Test
    fun `invalid packet does not stop scan`() = runTest {
        val controller = FakeScanController()
        val scanner = createScanner(controller)

        val deferred = backgroundScope.async { scanner.scanForCandidate().first() }
        runCurrent()
        controller.emitInvalidPacket(rssi = -50)
        controller.emitInvalidPacket(rssi = -45)
        runCurrent()

        assertThat(deferred.isCompleted).isFalse()
        assertThat(controller.stopCalls).isEqualTo(0)

        advanceTimeBy(2)
        runCurrent()

        assertThat(deferred.await()).isEqualTo(Outcome.FailureResult(Failure.ScanFailure.Timeout))
        assertThat(controller.stopCalls).isEqualTo(1)
    }

    private fun createScanner(controller: FakeScanController) = AndroidBleScanner(
        scanControllerFactory = { controller },
        advertisementPacketParser = AdvertisementPacketParser(),
        scanResponseParser = ScanResponseParser(),
        candidateAssembler = VolnaCandidateAssembler(
            com.example.volnabledemo.data.ble.SignalStrengthValidator(Int.MIN_VALUE),
            com.example.volnabledemo.data.ble.QrLinkBuilder("https://qr.nspk.ru/"),
        ),
        scanTimeoutMs = 1,
    )

    private class FakeScanController : ScanController {
        private var callback: ScanControllerCallback? = null
        var stopCalls: Int = 0

        override fun startScan(callback: ScanControllerCallback) {
            this.callback = callback
        }

        override fun stopScan() {
            stopCalls += 1
        }

        fun emitInvalidPacket(rssi: Int) {
            callback?.onScanResult(
                serviceData = byteArrayOf(0x7F),
                manufacturerData = byteArrayOf(0x01),
                rssi = rssi,
            )
        }
    }
}
