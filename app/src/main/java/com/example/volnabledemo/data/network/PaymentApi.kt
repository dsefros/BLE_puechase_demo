package com.example.volnabledemo.data.network

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import retrofit2.http.Body
import retrofit2.http.POST

interface PaymentApi {
    @POST("payments/submit")
    suspend fun submitPayment(@Body request: PaymentRequestDto): PaymentResponseDto
}

@Serializable
data class PaymentRequestDto(
    @SerialName("qrc_id") val qrcId: String,
    @SerialName("qr_link") val qrLink: String,
    @SerialName("amount_minor") val amountMinor: Long,
    @SerialName("merchant_name") val merchantName: String,
)

@Serializable
data class PaymentResponseDto(
    val success: Boolean,
    val operationId: String? = null,
)
