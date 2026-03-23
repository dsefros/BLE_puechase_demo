package com.example.volnabledemo

import com.example.volnabledemo.domain.error.Failure
import com.example.volnabledemo.domain.model.Outcome
import com.example.volnabledemo.domain.repository.PrerequisitesRepository
import com.example.volnabledemo.domain.usecase.CheckPrerequisitesUseCase
import com.google.common.truth.Truth.assertThat
import org.junit.Test

class CheckPrerequisitesUseCaseTest {
    @Test
    fun `returns failures in expected priority order`() {
        val useCase = CheckPrerequisitesUseCase(
            object : PrerequisitesRepository {
                override fun isBleSupported() = false
                override fun isBluetoothEnabled() = false
                override fun hasRequiredPermissions() = false
                override fun hasInternetConnection() = false
                override fun resolveFailure() = Failure.PrerequisiteFailure.BleUnsupported
            }
        )

        assertThat(useCase()).isEqualTo(Outcome.FailureResult(Failure.PrerequisiteFailure.BleUnsupported))
    }

    @Test
    fun `returns no internet when only connectivity is missing`() {
        val useCase = CheckPrerequisitesUseCase(
            object : PrerequisitesRepository {
                override fun isBleSupported() = true
                override fun isBluetoothEnabled() = true
                override fun hasRequiredPermissions() = true
                override fun hasInternetConnection() = false
                override fun resolveFailure() = Failure.PrerequisiteFailure.NoInternet
            }
        )

        assertThat(useCase()).isEqualTo(Outcome.FailureResult(Failure.PrerequisiteFailure.NoInternet))
    }
}
