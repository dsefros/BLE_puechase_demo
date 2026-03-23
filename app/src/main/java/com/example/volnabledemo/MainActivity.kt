package com.example.volnabledemo

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.volnabledemo.data.ble.AdvertisementPacketParser
import com.example.volnabledemo.data.ble.AndroidBleScanner
import com.example.volnabledemo.data.ble.QrLinkBuilder
import com.example.volnabledemo.data.ble.ScanResponseParser
import com.example.volnabledemo.data.ble.SignalStrengthValidator
import com.example.volnabledemo.data.ble.VolnaCandidateAssembler
import com.example.volnabledemo.data.network.PaymentApi
import com.example.volnabledemo.data.repository.PaymentRepositoryImpl
import com.example.volnabledemo.domain.model.PaymentFlowState
import com.example.volnabledemo.domain.model.VolnaCandidate
import com.example.volnabledemo.domain.usecase.CheckPrerequisitesUseCase
import com.example.volnabledemo.domain.usecase.ScanForCandidateUseCase
import com.example.volnabledemo.domain.usecase.SubmitPaymentUseCase
import com.example.volnabledemo.platform.AndroidPrerequisitesRepository
import com.example.volnabledemo.presentation.PaymentViewModel
import com.example.volnabledemo.ui.theme.VolnaBleDemoTheme
import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.kotlinx.serialization.asConverterFactory
import java.text.NumberFormat
import java.util.Locale
import java.util.concurrent.TimeUnit

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        val json = Json { ignoreUnknownKeys = true }
        val okHttp = OkHttpClient.Builder()
            .callTimeout(10, TimeUnit.SECONDS)
            .connectTimeout(10, TimeUnit.SECONDS)
            .readTimeout(10, TimeUnit.SECONDS)
            .addInterceptor(HttpLoggingInterceptor().apply { level = HttpLoggingInterceptor.Level.BASIC })
            .build()
        val paymentApi = Retrofit.Builder()
            .baseUrl(BuildConfig.PAYMENT_BASE_URL)
            .client(okHttp)
            .addConverterFactory(json.asConverterFactory("application/json".toMediaType()))
            .build()
            .create(PaymentApi::class.java)

        val viewModelFactory = PaymentViewModel.factory(
            CheckPrerequisitesUseCase(AndroidPrerequisitesRepository(this)),
            ScanForCandidateUseCase(
                AndroidBleScanner(
                    this,
                    AdvertisementPacketParser(),
                    ScanResponseParser(),
                    VolnaCandidateAssembler(
                        SignalStrengthValidator(BuildConfig.RSSI_THRESHOLD),
                        QrLinkBuilder(BuildConfig.SBP_PREFIX),
                    )
                )
            ),
            SubmitPaymentUseCase(PaymentRepositoryImpl(paymentApi))
        )

        setContent {
            VolnaBleDemoTheme {
                val viewModel: PaymentViewModel = viewModel(factory = viewModelFactory)
                val state by viewModel.state.collectAsState()
                val permissionLauncher = rememberLauncherForActivityResult(
                    contract = ActivityResultContracts.RequestMultiplePermissions()
                ) { granted ->
                    if (granted.values.all { it }) viewModel.startScan() else viewModel.onPermissionsDenied(AndroidPrerequisitesRepository.permissionDeniedMessage())
                }
                Surface(modifier = Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
                    AppScreen(
                        state = state,
                        onStartScan = {
                            permissionLauncher.launch(AndroidPrerequisitesRepository.requiredPermissions().toTypedArray())
                        },
                        onCancel = viewModel::reset,
                        onPay = viewModel::submitPayment,
                    )
                }
            }
        }
    }
}

@Composable
private fun AppScreen(
    state: PaymentFlowState,
    onStartScan: () -> Unit,
    onCancel: () -> Unit,
    onPay: (VolnaCandidate) -> Unit,
) {
    when (state) {
        PaymentFlowState.Idle -> HomeScreen(onStartScan)
        PaymentFlowState.CheckingPrerequisites,
        PaymentFlowState.Scanning -> LoadingScreen("Ищем ближайший терминал Волна…")
        is PaymentFlowState.ReadyForConfirmation -> PaymentConfirmScreen(state.candidate, onPay, onCancel)
        is PaymentFlowState.SubmittingPayment -> LoadingScreen("Отправляем demo-платеж…")
        is PaymentFlowState.PaymentSuccess -> SuccessScreen()
        is PaymentFlowState.PaymentError -> ErrorScreen(state.message, onCancel)
        is PaymentFlowState.BlockingError -> ErrorScreen(state.message, onCancel)
    }
}

@Composable
private fun HomeScreen(onStartScan: () -> Unit) {
    ScreenContainer {
        Text("Volna BLE Demo", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
        Spacer(Modifier.height(12.dp))
        Text("Поиск первого валидного BLE-кандидата и demo-only POST оплата.")
        Spacer(Modifier.height(24.dp))
        Button(onClick = onStartScan, modifier = Modifier.fillMaxWidth()) {
            Text("Начать сканирование BLE")
        }
    }
}

@Composable
private fun PaymentConfirmScreen(candidate: VolnaCandidate, onPay: (VolnaCandidate) -> Unit, onCancel: () -> Unit) {
    val currency = NumberFormat.getCurrencyInstance(Locale("ru", "RU"))
    ScreenContainer {
        Text("Подтвердите demo-оплату", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
        Spacer(Modifier.height(16.dp))
        Text("Мерчант: ${candidate.merchantName}")
        Text("Сумма: ${currency.format(candidate.amountMinor / 100.0)}")
        Text("QR Link: ${candidate.qrLink}")
        Spacer(Modifier.height(24.dp))
        Button(onClick = { onPay(candidate) }, modifier = Modifier.fillMaxWidth()) {
            Text("Оплатить ${currency.format(candidate.amountMinor / 100.0)}")
        }
        Spacer(Modifier.height(12.dp))
        Button(onClick = onCancel, modifier = Modifier.fillMaxWidth()) {
            Text("Отмена")
        }
    }
}

@Composable
private fun LoadingScreen(message: String) {
    ScreenContainer {
        CircularProgressIndicator()
        Spacer(Modifier.height(16.dp))
        Text(message)
    }
}

@Composable
private fun SuccessScreen() {
    ScreenContainer {
        Text("✔", color = Color(0xFF2E7D32), style = MaterialTheme.typography.displayLarge)
        Spacer(Modifier.height(12.dp))
        Text("Demo flow успешно завершен.")
    }
}

@Composable
private fun ErrorScreen(message: String, onBack: () -> Unit) {
    ScreenContainer {
        Text("Ошибка", color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.headlineSmall)
        Spacer(Modifier.height(12.dp))
        Text(message)
        Spacer(Modifier.height(24.dp))
        Button(onClick = onBack, modifier = Modifier.fillMaxWidth()) { Text("На главный экран") }
    }
}

@Composable
private fun ScreenContainer(content: @Composable () -> Unit) {
    Column(
        modifier = Modifier.fillMaxSize().padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
        content = { content() }
    )
}
