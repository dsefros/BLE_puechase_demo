package com.example.volnabledemo

import androidx.arch.core.executor.testing.InstantTaskExecutorRule
import com.example.volnabledemo.domain.model.PaymentFlowState
import com.example.volnabledemo.domain.model.VolnaCandidate
import com.example.volnabledemo.domain.repository.BleScanner
import com.example.volnabledemo.domain.repository.PaymentRepository
import com.example.volnabledemo.domain.repository.PrerequisitesRepository
import com.example.volnabledemo.domain.usecase.CheckPrerequisitesUseCase
import com.example.volnabledemo.domain.usecase.ScanForCandidateUseCase
import com.example.volnabledemo.domain.usecase.SubmitPaymentUseCase
import com.example.volnabledemo.presentation.PaymentViewModel
import com.google.common.truth.Truth.assertThat
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.emptyFlow
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

@OptIn(ExperimentalCoroutinesApi::class)
class PaymentViewModelTest {
    @get:Rule val instantRule = InstantTaskExecutorRule()
    private val dispatcher = StandardTestDispatcher()

    @Before fun setUp() { Dispatchers.setMain(dispatcher) }
    @After fun tearDown() { Dispatchers.resetMain() }

    @Test
    fun `happy path transitions to confirmation`() = runTest {
        val candidate = VolnaCandidate("QRC1", "https://qr.nspk.ru/QRC1", 1000, "Store", -50, -52)
        val viewModel = testViewModel(flowOf(Result.success(candidate)))

        viewModel.startScan()
        advanceUntilIdle()

        assertThat(viewModel.state.value).isEqualTo(PaymentFlowState.ReadyForConfirmation(candidate))
    }

    @Test
    fun `permission denied produces explicit blocking error`() {
        val viewModel = testViewModel(emptyFlow())

        viewModel.onPermissionsDenied("Permissions message")

        assertThat(viewModel.state.value).isEqualTo(
            PaymentFlowState.BlockingError(
                "Permissions message"
            )
        )
    }

    private fun testViewModel(scanFlow: kotlinx.coroutines.flow.Flow<Result<VolnaCandidate>>) = PaymentViewModel(
        CheckPrerequisitesUseCase(object : PrerequisitesRepository {
            override fun isBleSupported() = true
            override fun isBluetoothEnabled() = true
            override fun hasRequiredPermissions() = true
            override fun hasInternetConnection() = true
        }),
        ScanForCandidateUseCase(object : BleScanner {
            override fun scanForCandidate() = scanFlow
        }),
        SubmitPaymentUseCase(object : PaymentRepository {
            override suspend fun submitPayment(candidate: VolnaCandidate) = Result.success(Unit)
            override fun mapError(throwable: Throwable) = throw throwable
        })
    )
}
