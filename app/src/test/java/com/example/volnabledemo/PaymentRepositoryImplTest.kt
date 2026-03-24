package com.example.volnabledemo

import com.example.volnabledemo.data.network.PaymentApi
import com.example.volnabledemo.data.network.PaymentResponseDto
import com.example.volnabledemo.data.repository.PaymentRepositoryImpl
import com.example.volnabledemo.domain.error.Failure
import com.example.volnabledemo.domain.model.Outcome
import com.example.volnabledemo.domain.model.VolnaCandidate
import com.google.common.truth.Truth.assertThat
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.ResponseBody.Companion.toResponseBody
import org.junit.Test
import retrofit2.HttpException
import retrofit2.Response
import java.io.IOException

@OptIn(ExperimentalCoroutinesApi::class)
class PaymentRepositoryImplTest {
    private val candidate = VolnaCandidate("QRC1", "https://qr.nspk.ru/QRC1", 1000, "Store", -50, -52)

    @Test
    fun `returns success when sbp confirmation returns 2xx`() = runTest {
        val repository = PaymentRepositoryImpl(FakePaymentApi(confirmResponse = Response.success(Unit)))

        val result = repository.submitPayment(candidate)

        assertThat(result).isEqualTo(Outcome.Success(com.example.volnabledemo.domain.model.PaymentResult))
    }

    @Test
    fun `maps http 400 to host rejected`() = runTest {
        val repository = PaymentRepositoryImpl(FakePaymentApi(confirmException = httpException(400)))

        val result = repository.submitPayment(candidate)

        assertThat(result).isEqualTo(Outcome.FailureResult(Failure.PaymentFailure.HostRejected))
    }

    @Test
    fun `maps non 2xx confirmation response to host rejected`() = runTest {
        val repository = PaymentRepositoryImpl(
            FakePaymentApi(
                confirmResponse = Response.error(
                    409,
                    "conflict".toResponseBody("application/json".toMediaType())
                )
            )
        )

        val result = repository.submitPayment(candidate)

        assertThat(result).isEqualTo(Outcome.FailureResult(Failure.PaymentFailure.HostRejected))
    }

    @Test
    fun `maps http 500 to network`() = runTest {
        val repository = PaymentRepositoryImpl(FakePaymentApi(confirmException = httpException(500)))

        val result = repository.submitPayment(candidate)

        assertThat(result).isEqualTo(Outcome.FailureResult(Failure.PaymentFailure.Network))
    }

    @Test
    fun `maps io exception to network`() = runTest {
        val repository = PaymentRepositoryImpl(FakePaymentApi(confirmException = IOException("offline")))

        val result = repository.submitPayment(candidate)

        assertThat(result).isEqualTo(Outcome.FailureResult(Failure.PaymentFailure.Network))
    }

    private class FakePaymentApi(
        private val confirmResponse: Response<Unit>? = null,
        private val confirmException: Exception? = null,
    ) : PaymentApi {
        override suspend fun submitPayment(request: com.example.volnabledemo.data.network.PaymentRequestDto): PaymentResponseDto {
            return PaymentResponseDto(success = true)
        }

        override suspend fun confirmSbpPayment(
            url: String,
            status: String,
            statusCode: String,
            statusMessage: String,
        ): Response<Unit> {
            confirmException?.let { throw it }
            return confirmResponse ?: Response.success(Unit)
        }
    }

    private fun httpException(code: Int): HttpException = HttpException(
        Response.error<PaymentResponseDto>(
            code,
            "error".toResponseBody("application/json".toMediaType()),
        )
    )
}
