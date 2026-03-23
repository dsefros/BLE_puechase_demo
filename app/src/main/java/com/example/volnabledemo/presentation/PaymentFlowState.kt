package com.example.volnabledemo.presentation

import com.example.volnabledemo.domain.error.Failure
import com.example.volnabledemo.domain.model.VolnaCandidate

sealed interface PaymentFlowState {
    data object Idle : PaymentFlowState
    data object CheckingPrerequisites : PaymentFlowState
    data object Scanning : PaymentFlowState
    data class ReadyForConfirmation(val candidate: VolnaCandidate) : PaymentFlowState
    data class PaymentSuccess(val candidate: VolnaCandidate) : PaymentFlowState
    data class PaymentError(val failure: Failure.PaymentFailure) : PaymentFlowState
    data class BlockingError(val failure: Failure) : PaymentFlowState
    data class SubmittingPayment(val candidate: VolnaCandidate) : PaymentFlowState
}
