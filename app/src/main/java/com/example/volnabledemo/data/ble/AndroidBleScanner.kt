package com.example.volnabledemo.data.ble

import android.annotation.SuppressLint
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.os.ParcelUuid
import com.example.volnabledemo.BuildConfig
import com.example.volnabledemo.domain.model.VolnaCandidate
import com.example.volnabledemo.domain.model.VolnaContract
import com.example.volnabledemo.domain.repository.BleScanner
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.launch

class AndroidBleScanner(
    private val context: Context,
    private val advertisementPacketParser: AdvertisementPacketParser,
    private val scanResponseParser: ScanResponseParser,
    private val candidateAssembler: VolnaCandidateAssembler,
) : BleScanner {
    @SuppressLint("MissingPermission")
    override fun scanForCandidate(): Flow<Result<VolnaCandidate>> = callbackFlow {
        val scanner = context.getSystemService(BluetoothManager::class.java)?.adapter?.bluetoothLeScanner
        if (scanner == null) {
            trySend(Result.failure(IllegalStateException("BLE scanner unavailable")))
            close()
            return@callbackFlow
        }

        val callback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult) {
                val record = result.scanRecord ?: return
                val serviceData = record.getServiceData(ParcelUuid(VolnaContract.serviceUuid)) ?: return
                val manufacturerData = record.getManufacturerSpecificData(VolnaContract.manufacturerId) ?: return
                val candidate = advertisementPacketParser.parse(serviceData)
                    .mapCatching { adv ->
                        val response = scanResponseParser.parse(VolnaContract.manufacturerId, manufacturerData).getOrThrow()
                        candidateAssembler.assemble(adv, response, result.rssi).getOrThrow()
                    }
                if (candidate.isSuccess) {
                    trySend(candidate)
                    scanner.stopScan(this)
                    close()
                }
            }

            override fun onScanFailed(errorCode: Int) {
                trySend(Result.failure(IllegalStateException("BLE scan failed: $errorCode")))
                close()
            }
        }

        val settings = ScanSettings.Builder().setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY).build()
        val filters = listOf(ScanFilter.Builder().setServiceUuid(ParcelUuid(VolnaContract.serviceUuid)).build())
        scanner.startScan(filters, settings, callback)
        val timeoutJob = launch {
            kotlinx.coroutines.delay(BuildConfig.SCAN_TIMEOUT_MS)
            scanner.stopScan(callback)
            trySend(Result.failure(IllegalStateException("Scan timeout")))
            close()
        }
        awaitClose {
            timeoutJob.cancel()
            scanner.stopScan(callback)
        }
    }
}
