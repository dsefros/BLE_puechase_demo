package com.example.volnabledemo.app.di

import android.content.Context
import com.example.volnabledemo.BuildConfig
import com.example.volnabledemo.data.ble.AdvertisementPacketParser
import com.example.volnabledemo.data.ble.AndroidBleScanner
import com.example.volnabledemo.data.ble.QrLinkBuilder
import com.example.volnabledemo.data.ble.ScanResponseParser
import com.example.volnabledemo.data.ble.SignalStrengthValidator
import com.example.volnabledemo.data.ble.VolnaCandidateAssembler
import com.example.volnabledemo.data.network.PaymentApi
import com.example.volnabledemo.data.repository.PaymentRepositoryImpl
import com.example.volnabledemo.domain.repository.PaymentRepository
import com.example.volnabledemo.domain.usecase.CheckPrerequisitesUseCase
import com.example.volnabledemo.domain.usecase.ScanForCandidateUseCase
import com.example.volnabledemo.domain.usecase.SubmitPaymentUseCase
import com.example.volnabledemo.platform.AndroidPrerequisitesRepository
import com.example.volnabledemo.presentation.PaymentViewModel
import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.kotlinx.serialization.asConverterFactory
import java.util.concurrent.TimeUnit

class AppContainer(context: Context) {
    private val appContext = context.applicationContext

    private val json = Json { ignoreUnknownKeys = true }
    private val okHttp = OkHttpClient.Builder()
        .callTimeout(10, TimeUnit.SECONDS)
        .connectTimeout(10, TimeUnit.SECONDS)
        .readTimeout(10, TimeUnit.SECONDS)
        .addInterceptor(HttpLoggingInterceptor().apply { level = HttpLoggingInterceptor.Level.BASIC })
        .build()
    private val paymentApi: PaymentApi = Retrofit.Builder()
        .baseUrl(BuildConfig.PAYMENT_BASE_URL)
        .client(okHttp)
        .addConverterFactory(json.asConverterFactory("application/json".toMediaType()))
        .build()
        .create(PaymentApi::class.java)

    val paymentRepository: PaymentRepository = PaymentRepositoryImpl(paymentApi)
    private val prerequisitesRepository = AndroidPrerequisitesRepository(appContext)
    private val bleScanner = AndroidBleScanner(
        context = appContext,
        advertisementPacketParser = AdvertisementPacketParser(),
        scanResponseParser = ScanResponseParser(),
        candidateAssembler = VolnaCandidateAssembler(
            SignalStrengthValidator(BuildConfig.RSSI_THRESHOLD),
            QrLinkBuilder(BuildConfig.SBP_PREFIX),
        ),
    )

    val useCases = UseCases(
        checkPrerequisites = CheckPrerequisitesUseCase(prerequisitesRepository),
        scanForCandidate = ScanForCandidateUseCase(bleScanner),
        submitPayment = SubmitPaymentUseCase(paymentRepository),
    )

    fun paymentViewModelFactory() = PaymentViewModel.factory(
        checkPrerequisitesUseCase = useCases.checkPrerequisites,
        scanForCandidateUseCase = useCases.scanForCandidate,
        submitPaymentUseCase = useCases.submitPayment,
    )
}

data class UseCases(
    val checkPrerequisites: CheckPrerequisitesUseCase,
    val scanForCandidate: ScanForCandidateUseCase,
    val submitPayment: SubmitPaymentUseCase,
)
