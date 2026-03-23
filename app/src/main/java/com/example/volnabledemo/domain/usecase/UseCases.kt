package com.example.volnabledemo.domain.usecase

import com.example.volnabledemo.domain.error.Failure
import com.example.volnabledemo.domain.model.Outcome
import com.example.volnabledemo.domain.model.PaymentResult
import com.example.volnabledemo.domain.model.PrerequisiteResult
import com.example.volnabledemo.domain.model.ScanResult
import com.example.volnabledemo.domain.model.VolnaCandidate
import com.example.volnabledemo.domain.repository.BleScanner
import com.example.volnabledemo.domain.repository.PaymentRepository
import com.example.volnabledemo.domain.repository.PrerequisitesRepository
import kotlinx.coroutines.flow.Flow

class CheckPrerequisitesUseCase(private val repository: PrerequisitesRepository) {
    operator fun invoke(): Outcome<PrerequisiteResult, Failure.PrerequisiteFailure> =
        repository.resolveFailure()?.let { Outcome.FailureResult(it) } ?: Outcome.Success(PrerequisiteResult)
}

class ScanForCandidateUseCase(private val bleScanner: BleScanner) {
    operator fun invoke(): Flow<Outcome<ScanResult, Failure.ScanFailure>> = bleScanner.scanForCandidate()
}

class SubmitPaymentUseCase(private val paymentRepository: PaymentRepository) {
    suspend operator fun invoke(candidate: VolnaCandidate): Outcome<PaymentResult, Failure.PaymentFailure> = paymentRepository.submitPayment(candidate)
}
