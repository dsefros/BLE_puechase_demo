package com.example.volnabledemo.domain.repository

import com.example.volnabledemo.domain.model.PaymentFailureReason
import com.example.volnabledemo.domain.model.VolnaCandidate
import kotlinx.coroutines.flow.Flow

interface BleScanner {
    fun scanForCandidate(): Flow<Result<VolnaCandidate>>
}

interface PaymentRepository {
    suspend fun submitPayment(candidate: VolnaCandidate): Result<Unit>
    fun mapError(throwable: Throwable): PaymentFailureReason
}

interface PrerequisitesRepository {
    fun isBleSupported(): Boolean
    fun isBluetoothEnabled(): Boolean
    fun hasRequiredPermissions(): Boolean
    fun hasInternetConnection(): Boolean
}
