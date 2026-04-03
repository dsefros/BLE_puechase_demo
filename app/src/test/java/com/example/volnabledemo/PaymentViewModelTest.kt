package com.example.volnabledemo

import androidx.arch.core.executor.testing.InstantTaskExecutorRule
import com.example.volnabledemo.domain.error.Failure
import com.example.volnabledemo.domain.model.Outcome
import com.example.volnabledemo.domain.model.PaymentResult
import com.example.volnabledemo.domain.model.ScanResult
import com.example.volnabledemo.domain.model.VolnaCandidate
import com.example.volnabledemo.domain.repository.BleScanner
import com.example.volnabledemo.domain.repository.PaymentRepository
import com.example.volnabledemo.domain.repository.PrerequisitesRepository
import com.example.volnabledemo.domain.repository.SettingsRepository
import com.example.volnabledemo.domain.usecase.CheckPrerequisitesUseCase
import com.example.volnabledemo.domain.usecase.ScanForCandidateUseCase
import com.example.volnabledemo.domain.usecase.SubmitPaymentUseCase
import com.example.volnabledemo.presentation.PaymentFlowState
import com.example.volnabledemo.presentation.PaymentViewModel
import com.google.common.truth.Truth.assertThat
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import java.util.concurrent.atomic.AtomicInteger

@OptIn(ExperimentalCoroutinesApi::class)
class PaymentViewModelTest {
    @get:Rule val instantRule = InstantTaskExecutorRule()
    private val dispatcher = StandardTestDispatcher()

    @Before fun setUp() { Dispatchers.setMain(dispatcher) }
    @After fun tearDown() { Dispatchers.resetMain() }

    @Test
    fun `happy path transitions to confirmation`() = runTest {
        val candidate = VolnaCandidate("QRC1", "https://qr.nspk.ru/QRC1", 1000, "Store", -50, -52)
        val viewModel = testViewModel(flowOf(Outcome.Success(ScanResult(candidate))))

        viewModel.startScan()
        advanceUntilIdle()

        assertThat(viewModel.state.value).isEqualTo(PaymentFlowState.ReadyForConfirmation(candidate))
    }

    @Test
    fun `permission denied produces typed blocking error`() {
        val viewModel = testViewModel(emptyFlow())

        viewModel.onPermissionsDenied()

        assertThat(viewModel.state.value).isEqualTo(
            PaymentFlowState.BlockingError(Failure.PrerequisiteFailure.PermissionsDenied)
        )
    }

    @Test
    fun `startScan ignores second call while scan already running`() = runTest {
        val started = AtomicInteger(0)
        val gate = CompletableDeferred<Unit>()
        val scanFlow = flow {
            started.incrementAndGet()
            gate.await()
            emit(Outcome.FailureResult(Failure.ScanFailure.Timeout))
        }
        val viewModel = testViewModel(scanFlow)

        viewModel.startScan()
        viewModel.startScan()
        advanceUntilIdle()

        assertThat(started.get()).isEqualTo(1)
        gate.complete(Unit)
        advanceUntilIdle()
    }

    @Test
    fun `submitPayment ignores second call while submit already running`() = runTest {
        val submits = AtomicInteger(0)
        val gate = CompletableDeferred<Unit>()
        val candidate = VolnaCandidate("QRC1", "https://qr.nspk.ru/QRC1", 1000, "Store", -50, -52)
        val viewModel = PaymentViewModel(
            CheckPrerequisitesUseCase(testPrerequisitesRepository()),
            ScanForCandidateUseCase(object : BleScanner {
                override fun scanForCandidate(): Flow<Outcome<ScanResult, Failure.ScanFailure>> = emptyFlow()
            }),
            SubmitPaymentUseCase(object : PaymentRepository {
                override suspend fun submitPayment(candidate: VolnaCandidate): Outcome<PaymentResult, Failure.PaymentFailure> {
                    submits.incrementAndGet()
                    gate.await()
                    return Outcome.Success(PaymentResult)
                }
            }),
            FakeSettingsRepository()
        )

        viewModel.submitPayment(candidate)
        viewModel.submitPayment(candidate)
        advanceUntilIdle()

        assertThat(submits.get()).isEqualTo(1)
        gate.complete(Unit)
        advanceUntilIdle()
        assertThat(viewModel.state.value).isEqualTo(PaymentFlowState.PaymentSuccess(candidate))
    }

    private fun testViewModel(scanFlow: Flow<Outcome<ScanResult, Failure.ScanFailure>>) = PaymentViewModel(
        CheckPrerequisitesUseCase(testPrerequisitesRepository()),
        ScanForCandidateUseCase(object : BleScanner {
            override fun scanForCandidate() = scanFlow
        }),
        SubmitPaymentUseCase(object : PaymentRepository {
            override suspend fun submitPayment(candidate: VolnaCandidate) = Outcome.Success(PaymentResult)
        }),
        settingsDataStore = FakeSettingsRepository()
    )

    private class FakeSettingsRepository(initialAutoScanEnabled: Boolean = false) : SettingsRepository {
        private val state = MutableStateFlow(initialAutoScanEnabled)

        override val isAutoScanEnabled: Flow<Boolean> = state

        override suspend fun setAutoScanEnabled(enabled: Boolean) {
            state.value = enabled
        }
    }

    private fun testPrerequisitesRepository() = object : PrerequisitesRepository {
        override fun isBleSupported() = true
        override fun isBluetoothEnabled() = true
        override fun hasRequiredPermissions() = true
        override fun hasInternetConnection() = true
        override fun resolveFailure() = null
    }
}
