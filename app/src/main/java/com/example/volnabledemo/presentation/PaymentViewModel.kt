package com.example.volnabledemo.presentation

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.volnabledemo.domain.error.Failure
import com.example.volnabledemo.domain.model.Outcome
import com.example.volnabledemo.domain.model.VolnaCandidate
import com.example.volnabledemo.domain.usecase.CheckPrerequisitesUseCase
import com.example.volnabledemo.domain.usecase.ScanForCandidateUseCase
import com.example.volnabledemo.domain.usecase.SubmitPaymentUseCase
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class PaymentViewModel(
    private val checkPrerequisitesUseCase: CheckPrerequisitesUseCase,
    private val scanForCandidateUseCase: ScanForCandidateUseCase,
    private val submitPaymentUseCase: SubmitPaymentUseCase,
) : ViewModel() {
    private val _state = MutableStateFlow<PaymentFlowState>(PaymentFlowState.Idle)
    val state: StateFlow<PaymentFlowState> = _state.asStateFlow()

    private var scanJob: Job? = null
    private var submitJob: Job? = null

    fun startScan() {
        if (scanJob?.isActive == true) return
        scanJob?.cancel()
        submitJob?.cancel()
        scanJob = viewModelScope.launch {
            _state.value = PaymentFlowState.CheckingPrerequisites
            when (val precheck = checkPrerequisitesUseCase()) {
                is Outcome.FailureResult -> {
                    _state.value = PaymentFlowState.BlockingError(precheck.reason)
                    scanJob = null
                    return@launch
                }
                is Outcome.Success -> {
                    _state.value = PaymentFlowState.Scanning
                }
            }

            scanForCandidateUseCase().collect { result ->
                when (result) {
                    is Outcome.Success -> _state.value = PaymentFlowState.ReadyForConfirmation(result.value.candidate)
                    is Outcome.FailureResult -> _state.value = PaymentFlowState.BlockingError(result.reason)
                }
                scanJob = null
            }
        }.also { job ->
            job.invokeOnCompletion { if (scanJob === job) scanJob = null }
        }
    }

    fun onPermissionsDenied() {
        _state.value = PaymentFlowState.BlockingError(Failure.PrerequisiteFailure.PermissionsDenied)
    }

    fun submitPayment(candidate: VolnaCandidate) {
        if (submitJob?.isActive == true) return
        submitJob = viewModelScope.launch {
            _state.value = PaymentFlowState.SubmittingPayment(candidate)
            when (val result = submitPaymentUseCase(candidate)) {
                is Outcome.Success -> _state.value = PaymentFlowState.PaymentSuccess(candidate)
                is Outcome.FailureResult -> _state.value = PaymentFlowState.PaymentError(result.reason)
            }
        }.also { job ->
            job.invokeOnCompletion { if (submitJob === job) submitJob = null }
        }
    }

    fun acknowledgeSuccess() {
        if (_state.value is PaymentFlowState.PaymentSuccess) {
            _state.value = PaymentFlowState.Idle
        }
    }

    fun reset() {
        scanJob?.cancel()
        submitJob?.cancel()
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
