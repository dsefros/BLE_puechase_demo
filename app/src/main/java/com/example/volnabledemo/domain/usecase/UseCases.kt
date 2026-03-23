package com.example.volnabledemo.domain.usecase

import com.example.volnabledemo.domain.model.ScanFailureReason
import com.example.volnabledemo.domain.model.VolnaCandidate
import com.example.volnabledemo.domain.repository.BleScanner
import com.example.volnabledemo.domain.repository.PaymentRepository
import com.example.volnabledemo.domain.repository.PrerequisitesRepository
import kotlinx.coroutines.flow.Flow

class CheckPrerequisitesUseCase(private val repository: PrerequisitesRepository) {
    operator fun invoke(): Result<Unit> = runCatching {
        when {
            !repository.isBleSupported() -> error(ScanFailureReason.BleUnsupported.name)
            !repository.isBluetoothEnabled() -> error(ScanFailureReason.BluetoothDisabled.name)
            !repository.hasRequiredPermissions() -> error(ScanFailureReason.PermissionsDenied.name)
            !repository.hasInternetConnection() -> error(ScanFailureReason.NoInternet.name)
        }
    }
}

class ScanForCandidateUseCase(private val bleScanner: BleScanner) {
    operator fun invoke(): Flow<Result<VolnaCandidate>> = bleScanner.scanForCandidate()
}

class SubmitPaymentUseCase(private val paymentRepository: PaymentRepository) {
    suspend operator fun invoke(candidate: VolnaCandidate): Result<Unit> = paymentRepository.submitPayment(candidate)
}
