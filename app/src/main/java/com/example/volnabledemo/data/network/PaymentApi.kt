package com.example.volnabledemo.data.network

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.Query
import retrofit2.http.Url

interface PaymentApi {
    @POST("payments/submit")
    suspend fun submitPayment(@Body request: PaymentRequestDto): PaymentResponseDto

    @GET
    suspend fun confirmSbpPayment(
        @Url url: String,
        @Query("status") status: String,
        @Query("statusCode") statusCode: String,
        @Query("statusMessage") statusMessage: String,
    ): Response<Unit>
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
