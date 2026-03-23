package com.example.volnabledemo.presentation

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.volnabledemo.domain.model.PaymentFlowState
import com.example.volnabledemo.domain.model.VolnaCandidate
import com.example.volnabledemo.domain.usecase.CheckPrerequisitesUseCase
import com.example.volnabledemo.domain.usecase.ScanForCandidateUseCase
import com.example.volnabledemo.domain.usecase.SubmitPaymentUseCase
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.launch

class PaymentViewModel(
    private val checkPrerequisitesUseCase: CheckPrerequisitesUseCase,
    private val scanForCandidateUseCase: ScanForCandidateUseCase,
    private val submitPaymentUseCase: SubmitPaymentUseCase,
) : ViewModel() {
    private val _state = MutableStateFlow<PaymentFlowState>(PaymentFlowState.Idle)
    val state: StateFlow<PaymentFlowState> = _state.asStateFlow()

    fun startScan() {
        viewModelScope.launch {
            _state.value = PaymentFlowState.CheckingPrerequisites
            val precheck = checkPrerequisitesUseCase()
            if (precheck.isFailure) {
                _state.value = PaymentFlowState.BlockingError(precheck.exceptionOrNull()?.message.orEmpty())
                return@launch
            }
            _state.value = PaymentFlowState.Scanning
            scanForCandidateUseCase()
                .catch { _state.value = PaymentFlowState.BlockingError(it.message ?: "Scan failed") }
                .collect { result ->
                    result.onSuccess { candidate ->
                        _state.value = PaymentFlowState.ReadyForConfirmation(candidate)
                    }.onFailure {
                        _state.value = PaymentFlowState.BlockingError(it.message ?: "Terminal not found")
                    }
                }
        }
    }

    fun onPermissionsDenied(message: String) {
        _state.value = PaymentFlowState.BlockingError(message)
    }

    fun submitPayment(candidate: VolnaCandidate) {
        viewModelScope.launch {
            _state.value = PaymentFlowState.SubmittingPayment(candidate)
            val result = submitPaymentUseCase(candidate)
            result.onSuccess {
                _state.value = PaymentFlowState.PaymentSuccess(candidate)
                delay(2500)
                _state.value = PaymentFlowState.Idle
            }.onFailure {
                _state.value = PaymentFlowState.PaymentError(it.message ?: "Payment failed")
            }
        }
    }

    fun reset() {
        _state.value = PaymentFlowState.Idle
    }

    companion object {
        fun factory(
            checkPrerequisitesUseCase: CheckPrerequisitesUseCase,
            scanForCandidateUseCase: ScanForCandidateUseCase,
            submitPaymentUseCase: SubmitPaymentUseCase,
        ): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T = PaymentViewModel(
                checkPrerequisitesUseCase,
                scanForCandidateUseCase,
                submitPaymentUseCase,
            ) as T
        }
    }
}
