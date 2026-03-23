package com.example.volnabledemo.data.repository

import com.example.volnabledemo.data.network.PaymentApi
import com.example.volnabledemo.data.network.PaymentRequestDto
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
        val response = paymentApi.submitPayment(
            PaymentRequestDto(
                qrcId = candidate.qrcId,
                qrLink = candidate.qrLink,
                amountMinor = candidate.amountMinor,
                merchantName = candidate.merchantName,
            )
        )
        if (response.success) Outcome.Success(PaymentResult) else Outcome.FailureResult(Failure.PaymentFailure.HostRejected)
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
}

private fun HttpException.isClientError(): Boolean = code() in 400..499
