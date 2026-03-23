package com.example.volnabledemo.data.repository

import com.example.volnabledemo.data.network.PaymentApi
import com.example.volnabledemo.data.network.PaymentRequestDto
import com.example.volnabledemo.domain.model.PaymentFailureReason
import com.example.volnabledemo.domain.model.VolnaCandidate
import com.example.volnabledemo.domain.repository.PaymentRepository
import retrofit2.HttpException
import java.io.IOException
import java.net.SocketTimeoutException

class PaymentRepositoryImpl(private val paymentApi: PaymentApi) : PaymentRepository {
    override suspend fun submitPayment(candidate: VolnaCandidate): Result<Unit> = runCatching {
        val response = paymentApi.submitPayment(
            PaymentRequestDto(
                qrcId = candidate.qrcId,
                qrLink = candidate.qrLink,
                amountMinor = candidate.amountMinor,
                merchantName = candidate.merchantName,
            )
        )
        require(response.success) { "Host returned unsuccessful response" }
    }

    override fun mapError(throwable: Throwable): PaymentFailureReason = when (throwable) {
        is SocketTimeoutException -> PaymentFailureReason.HostTimeout
        is HttpException, is IOException -> PaymentFailureReason.HostError
        else -> PaymentFailureReason.InvalidPayload
    }
}
