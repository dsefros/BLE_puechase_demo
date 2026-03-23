package com.example.volnabledemo.data.ble

import android.annotation.SuppressLint
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.os.ParcelUuid
import com.example.volnabledemo.BuildConfig
import com.example.volnabledemo.domain.error.Failure
import com.example.volnabledemo.domain.model.Outcome
import com.example.volnabledemo.domain.model.ScanResult as DomainScanResult
import com.example.volnabledemo.domain.model.VolnaContract
import com.example.volnabledemo.domain.repository.BleScanner
import java.util.concurrent.atomic.AtomicBoolean
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.launch

interface ScanController {
    fun startScan(callback: ScanControllerCallback)
    fun stopScan()
}

interface ScanControllerCallback {
    fun onScanResult(serviceData: ByteArray?, manufacturerData: ByteArray?, rssi: Int)
    fun onScanFailed(errorCode: Int)
}

private class BluetoothLeScanController(
    private val context: Context,
) : ScanController {
    private var scannerCallback: ScanCallback? = null
    private val scanner = context.getSystemService(BluetoothManager::class.java)?.adapter?.bluetoothLeScanner

    @SuppressLint("MissingPermission")
    override fun startScan(callback: ScanControllerCallback) {
        val bleScanner = requireNotNull(scanner)
        val wrapped = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: android.bluetooth.le.ScanResult) {
                val record = result.scanRecord
                callback.onScanResult(
                    serviceData = record?.getServiceData(ParcelUuid(VolnaContract.serviceUuid)),
                    manufacturerData = record?.getManufacturerSpecificData(VolnaContract.manufacturerId),
                    rssi = result.rssi,
                )
            }

            override fun onScanFailed(errorCode: Int) = callback.onScanFailed(errorCode)
        }
        scannerCallback = wrapped
        val settings = ScanSettings.Builder().setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY).build()
        val filters = listOf(ScanFilter.Builder().setServiceUuid(ParcelUuid(VolnaContract.serviceUuid)).build())
        bleScanner.startScan(filters, settings, wrapped)
    }

    @SuppressLint("MissingPermission")
    override fun stopScan() {
        scannerCallback?.let { callback -> scanner?.stopScan(callback) }
        scannerCallback = null
    }
}

class AndroidBleScanner(
    private val scanControllerFactory: () -> ScanController?,
    private val advertisementPacketParser: AdvertisementPacketParser,
    private val scanResponseParser: ScanResponseParser,
    private val candidateAssembler: VolnaCandidateAssembler,
    private val scanTimeoutMs: Long = BuildConfig.SCAN_TIMEOUT_MS,
) : BleScanner {
    constructor(
        context: Context,
        advertisementPacketParser: AdvertisementPacketParser,
        scanResponseParser: ScanResponseParser,
        candidateAssembler: VolnaCandidateAssembler,
        scanTimeoutMs: Long = BuildConfig.SCAN_TIMEOUT_MS,
    ) : this(
        scanControllerFactory = { BluetoothLeScanController(context) },
        advertisementPacketParser = advertisementPacketParser,
        scanResponseParser = scanResponseParser,
        candidateAssembler = candidateAssembler,
        scanTimeoutMs = scanTimeoutMs,
    )

    override fun scanForCandidate(): Flow<Outcome<DomainScanResult, Failure.ScanFailure>> = callbackFlow {
        val controller = scanControllerFactory()
        if (controller == null) {
            trySend(Outcome.FailureResult(Failure.ScanFailure.HardwareError))
            close()
            return@callbackFlow
        }

        val terminal = AtomicBoolean(false)
        fun complete(outcome: Outcome<DomainScanResult, Failure.ScanFailure>) {
            if (terminal.compareAndSet(false, true)) {
                controller.stopScan()
                trySend(outcome)
                close()
            }
        }

        val timeoutJob = launch {
            kotlinx.coroutines.delay(scanTimeoutMs)
            complete(Outcome.FailureResult(Failure.ScanFailure.Timeout))
        }

        controller.startScan(object : ScanControllerCallback {
            override fun onScanResult(serviceData: ByteArray?, manufacturerData: ByteArray?, rssi: Int) {
                if (terminal.get()) return
                if (serviceData == null || manufacturerData == null) return
                val candidate = advertisementPacketParser.parse(serviceData)
                    .mapCatching { adv ->
                        val response = scanResponseParser.parse(VolnaContract.manufacturerId, manufacturerData).getOrThrow()
                        candidateAssembler.assemble(adv, response, rssi).getOrThrow()
                    }
                if (candidate.isSuccess) {
                    timeoutJob.cancel()
                    complete(Outcome.Success(DomainScanResult(candidate.getOrThrow())))
                }
            }

            override fun onScanFailed(errorCode: Int) {
                timeoutJob.cancel()
                complete(Outcome.FailureResult(Failure.ScanFailure.HardwareError))
            }
        })

        awaitClose {
            timeoutJob.cancel()
            if (terminal.compareAndSet(false, true)) {
                controller.stopScan()
            }
        }
    }
}
