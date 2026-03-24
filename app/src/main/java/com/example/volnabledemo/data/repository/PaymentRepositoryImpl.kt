package com.example.volnabledemo.data.repository

import com.example.volnabledemo.data.network.PaymentApi
import com.example.volnabledemo.domain.error.Failure
import com.example.volnabledemo.domain.model.Outcome
import com.example.volnabledemo.domain.model.PaymentResult
import com.example.volnabledemo.domain.model.VolnaCandidate
import com.example.volnabledemo.domain.repository.PaymentRepository
import kotlinx.serialization.SerializationException
import retrofit2.HttpException
import java.io.IOException

class PaymentRepositoryImpl(private val paymentApi: PaymentApi) : PaymentRepository {
    override suspend fun submitPayment(candidate: VolnaCandidate): Outcome<PaymentResult, Failure.PaymentFailure> = try {
        val confirmationResponse = paymentApi.confirmSbpPayment(
            url = "$SBP_CONFIRMATION_URL/${candidate.qrcId}",
            status = SUCCESS_STATUS,
            statusCode = SUCCESS_STATUS,
            statusMessage = SUCCESS_STATUS,
        )

        if (confirmationResponse.isSuccessful) {
            Outcome.Success(PaymentResult)
        } else {
            Outcome.FailureResult(if (confirmationResponse.code() in 400..499) Failure.PaymentFailure.HostRejected else Failure.PaymentFailure.Network)
        }
    } catch (exception: HttpException) {
        Outcome.FailureResult(
            if (exception.isClientError()) Failure.PaymentFailure.HostRejected else Failure.PaymentFailure.Network
        )
    } catch (_: IOException) {
        Outcome.FailureResult(Failure.PaymentFailure.Network)
    } catch (_: SerializationException) {
        Outcome.FailureResult(Failure.PaymentFailure.Serialization)
    } catch (_: IllegalArgumentException) {
        Outcome.FailureResult(Failure.PaymentFailure.Serialization)
    } catch (_: Exception) {
        Outcome.FailureResult(Failure.PaymentFailure.Unknown)
    }

    private companion object {
        const val SBP_CONFIRMATION_URL = "https://beta-ecom.payment-guide.ru/api/internal/sbp/pay"
        const val SUCCESS_STATUS = "SUCCESS"
    }
}

private fun HttpException.isClientError(): Boolean = code() in 400..499
