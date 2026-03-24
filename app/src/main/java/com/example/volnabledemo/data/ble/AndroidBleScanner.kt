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
        BleLog.d("BLE_Scanner", "startScan() called")
        val bleScanner = requireNotNull(scanner)
        val wrapped = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: android.bluetooth.le.ScanResult) {
                BleLog.d("BLE_Scanner", "========================================")
                BleLog.d("BLE_Scanner", "📱 DEVICE FOUND: ${result.device.address}")
                BleLog.d("BLE_Scanner", "   Name: ${result.device.name ?: "Unknown"}")
                BleLog.d("BLE_Scanner", "   RSSI: ${result.rssi}")

                val record = result.scanRecord
                if (record != null) {
                    BleLog.d("BLE_Scanner", "   Service UUIDs: ${record.serviceUuids ?: "none"}")
                    BleLog.d("BLE_Scanner", "   Service Data keys: ${record.serviceData?.keys ?: "none"}")

                    // Проверяем, есть ли наш UUID
                    val hasOurUuid = record.serviceUuids?.any {
                        it.uuid == VolnaContract.serviceUuid
                    } ?: false
                    BleLog.d("BLE_Scanner", "   Has Volna UUID: $hasOurUuid")

                    val serviceData = record.getServiceData(ParcelUuid(VolnaContract.serviceUuid))
                    val manufacturerData = record.getManufacturerSpecificData(VolnaContract.manufacturerId)

                    if (serviceData != null) {
                        BleLog.d("BLE_Scanner", "   ✅ ServiceData: ${serviceData.size} bytes")
                        BleLog.d("BLE_Scanner", "   ServiceData hex: ${serviceData.joinToString("") { "%02x".format(it) }}")
                    } else {
                        BleLog.d("BLE_Scanner", "   ❌ ServiceData: null")
                    }

                    if (manufacturerData != null) {
                        BleLog.d("BLE_Scanner", "   ✅ ManufacturerData: ${manufacturerData.size} bytes")
                        BleLog.d("BLE_Scanner", "   ManufacturerData hex: ${manufacturerData.joinToString("") { "%02x".format(it) }}")
                        if (manufacturerData.size >= 4) {
                            val amount = (manufacturerData[0].toInt() shl 24) or
                                    (manufacturerData[1].toInt() shl 16) or
                                    (manufacturerData[2].toInt() shl 8) or
                                    (manufacturerData[3].toInt())
                            BleLog.d("BLE_Scanner", "   Amount from bytes: $amount")
                        }
                    } else {
                        BleLog.d("BLE_Scanner", "   ❌ ManufacturerData: null")
                    }

                    // Временно вызываем callback для всех устройств для отладки
                    callback.onScanResult(serviceData, manufacturerData, result.rssi)
                } else {
                    BleLog.d("BLE_Scanner", "   No scan record")
                    callback.onScanResult(null, null, result.rssi)
                }
            }

            override fun onScanFailed(errorCode: Int) {
                BleLog.e("BLE_Scanner", "onScanFailed - errorCode: $errorCode")
                callback.onScanFailed(errorCode)
            }
        }
        scannerCallback = wrapped
        val settings = ScanSettings.Builder().setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY).build()
        // Временно убираем фильтр, чтобы видеть ВСЕ устройства
        val filters = emptyList<ScanFilter>()
        BleLog.d("BLE_Scanner", "Starting BLE scan WITHOUT filters (seeing all devices)")
        bleScanner.startScan(filters, settings, wrapped)
    }

    @SuppressLint("MissingPermission")
    override fun stopScan() {
        BleLog.d("BLE_Scanner", "stopScan() called")
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
        BleLog.d("BLE_Scanner", "scanForCandidate() started")
        val controller = scanControllerFactory()
        if (controller == null) {
            BleLog.e("BLE_Scanner", "Controller is null - HardwareError")
            trySend(Outcome.FailureResult(Failure.ScanFailure.HardwareError))
            close()
            return@callbackFlow
        }

        val terminal = AtomicBoolean(false)
        fun complete(outcome: Outcome<DomainScanResult, Failure.ScanFailure>) {
            if (terminal.compareAndSet(false, true)) {
                BleLog.d("BLE_Scanner", "Complete with outcome: $outcome")
                controller.stopScan()
                trySend(outcome)
                close()
            }
        }

        val timeoutJob = launch {
            BleLog.d("BLE_Scanner", "Scan timeout set to ${scanTimeoutMs}ms")
            kotlinx.coroutines.delay(scanTimeoutMs)
            BleLog.d("BLE_Scanner", "Scan timeout reached")
            complete(Outcome.FailureResult(Failure.ScanFailure.Timeout))
        }

        controller.startScan(object : ScanControllerCallback {
            override fun onScanResult(serviceData: ByteArray?, manufacturerData: ByteArray?, rssi: Int) {
                BleLog.d("BLE_Scanner", "onScanResult received in callback")

                if (terminal.get()) {
                    BleLog.d("BLE_Scanner", "Already terminated, skipping")
                    return
                }

                // Временно: показываем все устройства, даже без наших данных
                if (serviceData == null || manufacturerData == null) {
                    BleLog.d("BLE_Scanner", "Device does NOT have Volna serviceData or manufacturerData")
                    return
                }

                BleLog.d("BLE_Scanner", "✅ Device HAS Volna data! Processing...")
                BleLog.d("BLE_Scanner", "ServiceData size: ${serviceData.size}")
                BleLog.d("BLE_Scanner", "ManufacturerData size: ${manufacturerData.size}")

                BleLog.d("BLE_Scanner", "Parsing serviceData...")
                val advResult = advertisementPacketParser.parse(serviceData)
                if (advResult.isFailure) {
                    BleLog.e("BLE_Scanner", "Failed to parse advertisement: ${advResult.exceptionOrNull()?.message}")
                    return
                }
                val advertisementPacket = advResult.getOrThrow()
                BleLog.d("BLE_Scanner", "✅ Advertisement parsed: qrcId=${advertisementPacket.qrcId}, version=${advertisementPacket.packetVersion}")

                BleLog.d("BLE_Scanner", "Parsing manufacturerData...")
                val scanResult = scanResponseParser.parse(VolnaContract.manufacturerId, manufacturerData)
                if (scanResult.isFailure) {
                    BleLog.e("BLE_Scanner", "Failed to parse scan response: ${scanResult.exceptionOrNull()?.message}")
                    return
                }
                val scanResponseData = scanResult.getOrThrow()
                BleLog.d("BLE_Scanner", "✅ Scan response parsed: amount=${scanResponseData.amountMinor}, merchant=${scanResponseData.merchantName}")

                BleLog.d("BLE_Scanner", "Assembling candidate...")
                val candidateResult = candidateAssembler.assemble(advertisementPacket, scanResponseData, rssi)
                if (candidateResult.isSuccess) {
                    val candidate = candidateResult.getOrThrow()
                    BleLog.d("BLE_Scanner", "🎉🎉🎉 SUCCESS! Candidate assembled: ${candidate.merchantName}, amount=${candidate.amountMinor}")
                    timeoutJob.cancel()
                    complete(Outcome.Success(DomainScanResult(candidate)))
                } else {
                    BleLog.e("BLE_Scanner", "Failed to assemble candidate: ${candidateResult.exceptionOrNull()?.message}")
                }
            }

            override fun onScanFailed(errorCode: Int) {
                BleLog.e("BLE_Scanner", "onScanFailed in callback: $errorCode")
                timeoutJob.cancel()
                complete(Outcome.FailureResult(Failure.ScanFailure.HardwareError))
            }
        })

        awaitClose {
            BleLog.d("BLE_Scanner", "awaitClose - cleaning up")
            timeoutJob.cancel()
            if (terminal.compareAndSet(false, true)) {
                controller.stopScan()
            }
        }
    }
}