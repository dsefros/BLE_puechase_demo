package com.example.volnabledemo.domain.repository

import com.example.volnabledemo.domain.error.Failure
import com.example.volnabledemo.domain.model.Outcome
import com.example.volnabledemo.domain.model.PaymentResult
import com.example.volnabledemo.domain.model.ScanResult
import com.example.volnabledemo.domain.model.VolnaCandidate
import kotlinx.coroutines.flow.Flow

interface BleScanner {
    fun scanForCandidate(): Flow<Outcome<ScanResult, Failure.ScanFailure>>
}

interface PaymentRepository {
    suspend fun submitPayment(candidate: VolnaCandidate): Outcome<PaymentResult, Failure.PaymentFailure>
}

interface PrerequisitesRepository {
    fun isBleSupported(): Boolean
    fun isBluetoothEnabled(): Boolean
    fun hasRequiredPermissions(): Boolean
    fun hasInternetConnection(): Boolean
    fun resolveFailure(): Failure.PrerequisiteFailure?
}

interface SettingsRepository {
    val isAutoScanEnabled: Flow<Boolean>
    suspend fun setAutoScanEnabled(enabled: Boolean)
}
