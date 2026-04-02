package com.example.volnabledemo.presentation

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.volnabledemo.data.settings.SettingsDataStore
import com.example.volnabledemo.domain.error.Failure
import com.example.volnabledemo.domain.model.Outcome
import com.example.volnabledemo.domain.model.VolnaCandidate
import com.example.volnabledemo.domain.usecase.CheckPrerequisitesUseCase
import com.example.volnabledemo.domain.usecase.ScanForCandidateUseCase
import com.example.volnabledemo.domain.usecase.SubmitPaymentUseCase
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.flow.first

class PaymentViewModel(
    private val checkPrerequisitesUseCase: CheckPrerequisitesUseCase,
    private val scanForCandidateUseCase: ScanForCandidateUseCase,
    private val submitPaymentUseCase: SubmitPaymentUseCase,
    private val settingsDataStore: SettingsDataStore,  // 👈 ДОБАВИТЬ
) : ViewModel() {
    private val _state = MutableStateFlow<PaymentFlowState>(PaymentFlowState.Idle)
    val state: StateFlow<PaymentFlowState> = _state.asStateFlow()

    // Настройка автосканирования
    private val _isAutoScanEnabled = MutableStateFlow(false)
    val isAutoScanEnabled: StateFlow<Boolean> = _isAutoScanEnabled.asStateFlow()

    // Канал для отправки уведомлений
    private val _notificationEvent = MutableSharedFlow<NotificationEvent>()
    val notificationEvent = _notificationEvent.asSharedFlow()

    private var scanJob: Job? = null
    private var submitJob: Job? = null

    init {
        viewModelScope.launch {
            settingsDataStore.isAutoScanEnabled.collect { enabled ->
                _isAutoScanEnabled.value = enabled
            }
        }
    }

    fun onAppStart() {
        viewModelScope.launch {
            val enabled = settingsDataStore.isAutoScanEnabled.first()
            android.util.Log.d("PaymentViewModel", "onAppStart: autoScanEnabled = $enabled")
            if (enabled) {
                startScan()
            }
        }
    }

    fun toggleAutoScan(enabled: Boolean) {
        viewModelScope.launch {
            android.util.Log.d("PaymentViewModel", "toggleAutoScan: $enabled")
            settingsDataStore.setAutoScanEnabled(enabled)

            if (enabled) {
                // Если включили - запускаем сканирование
                startScan()
            } else {
                // Если выключили - останавливаем сканирование и сбрасываем состояние
                stopScan()
            }
        }
    }

    fun stopScan() {
        android.util.Log.d("PaymentViewModel", "stopScan called")
        scanJob?.cancel()
        scanJob = null
        submitJob?.cancel()
        submitJob = null
        if (_state.value is PaymentFlowState.Scanning ||
            _state.value is PaymentFlowState.CheckingPrerequisites ||
            _state.value is PaymentFlowState.ReadyForConfirmation) {
            _state.value = PaymentFlowState.Idle
            // Если автосканирование выключено, после остановки ничего не делаем
            // Если включено - не перезапускаем, т.к. это ручная остановка
        }
    }

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
                    is Outcome.Success -> {
                        _state.value = PaymentFlowState.ReadyForConfirmation(result.value.candidate)
                        sendNotification(NotificationEvent.CandidateFound(result.value.candidate))
                    }
                    is Outcome.FailureResult -> {
                        _state.value = PaymentFlowState.BlockingError(result.reason)
                    }
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
                is Outcome.Success -> {
                    _state.value = PaymentFlowState.PaymentSuccess(candidate)
                    sendNotification(NotificationEvent.PaymentSuccess(candidate))
                }
                is Outcome.FailureResult -> {
                    _state.value = PaymentFlowState.PaymentError(result.reason)
                    sendNotification(NotificationEvent.PaymentError(
                        merchantName = candidate.merchantName,
                        amountMinor = candidate.amountMinor,
                        errorMessage = result.reason.toString()
                    ))
                }
            }
        }.also { job ->
            job.invokeOnCompletion { if (submitJob === job) submitJob = null }
        }
    }

    fun acknowledgeSuccess() {
        if (_state.value is PaymentFlowState.PaymentSuccess) {
            _state.value = PaymentFlowState.Idle
            // После возврата на главный экран, если автосканирование включено - перезапускаем
            viewModelScope.launch {
                if (_isAutoScanEnabled.value) {
                    startScan()
                }
            }
        }
    }

    fun reset() {
        scanJob?.cancel()
        submitJob?.cancel()
        _state.value = PaymentFlowState.Idle
        // После сброса (отмена сканирования или ошибка), если автосканирование включено - перезапускаем
        viewModelScope.launch {
            if (_isAutoScanEnabled.value) {
                startScan()
            }
        }
    }

    private suspend fun sendNotification(event: NotificationEvent) {
        _notificationEvent.emit(event)
    }

    sealed class NotificationEvent {
        data class CandidateFound(val candidate: VolnaCandidate) : NotificationEvent()
        data class PaymentSuccess(val candidate: VolnaCandidate) : NotificationEvent()
        data class PaymentError(val merchantName: String, val amountMinor: Long, val errorMessage: String) : NotificationEvent()
    }

    companion object {
        fun factory(
            checkPrerequisitesUseCase: CheckPrerequisitesUseCase,
            scanForCandidateUseCase: ScanForCandidateUseCase,
            submitPaymentUseCase: SubmitPaymentUseCase,
            settingsDataStore: SettingsDataStore,
        ): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T = PaymentViewModel(
                checkPrerequisitesUseCase,
                scanForCandidateUseCase,
                submitPaymentUseCase,
                settingsDataStore,  // 👈 ДОБАВИТЬ
            ) as T
        }
    }
}