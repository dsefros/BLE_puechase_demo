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
import com.example.volnabledemo.app.di.AppContainer
import com.example.volnabledemo.domain.error.Failure
import com.example.volnabledemo.domain.model.VolnaCandidate
import com.example.volnabledemo.platform.AndroidPrerequisitesRepository
import com.example.volnabledemo.presentation.PaymentFlowState
import com.example.volnabledemo.presentation.PaymentViewModel
import com.example.volnabledemo.ui.theme.VolnaBleDemoTheme
import java.text.NumberFormat
import java.util.Locale

class MainActivity : ComponentActivity() {
    private val appContainer by lazy { AppContainer(this) }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        setContent {
            VolnaBleDemoTheme {
                val viewModel: PaymentViewModel = viewModel(factory = appContainer.paymentViewModelFactory())
                val state by viewModel.state.collectAsState()
                val permissionLauncher = rememberLauncherForActivityResult(
                    contract = ActivityResultContracts.RequestMultiplePermissions()
                ) { granted ->
                    if (granted.values.all { it }) viewModel.startScan() else viewModel.onPermissionsDenied()
                }
                Surface(modifier = Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
                    AppScreen(
                        state = state,
                        onStartScan = {
                            permissionLauncher.launch(AndroidPrerequisitesRepository.requiredPermissions().toTypedArray())
                        },
                        onCancel = viewModel::reset,
                        onPay = viewModel::submitPayment,
                        onAcknowledgeSuccess = viewModel::acknowledgeSuccess,
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
    onAcknowledgeSuccess: () -> Unit,
) {
    when (state) {
        PaymentFlowState.Idle -> HomeScreen(onStartScan)
        PaymentFlowState.CheckingPrerequisites,
        PaymentFlowState.Scanning -> LoadingScreen("Ищем ближайший терминал Волна…")
        is PaymentFlowState.ReadyForConfirmation -> PaymentConfirmScreen(state.candidate, onPay, onCancel)
        is PaymentFlowState.SubmittingPayment -> LoadingScreen("Отправляем demo-платеж…")
        is PaymentFlowState.PaymentSuccess -> SuccessScreen(onAcknowledgeSuccess)
        is PaymentFlowState.PaymentError -> ErrorScreen(paymentFailureMessage(state.failure), onCancel)
        is PaymentFlowState.BlockingError -> ErrorScreen(failureMessage(state.failure), onCancel)
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
private fun SuccessScreen(onDone: () -> Unit) {
    ScreenContainer {
        Text("✔", color = Color(0xFF2E7D32), style = MaterialTheme.typography.displayLarge)
        Spacer(Modifier.height(12.dp))
        Text("Demo flow успешно завершен.")
        Spacer(Modifier.height(24.dp))
        Button(onClick = onDone, modifier = Modifier.fillMaxWidth()) { Text("На главный экран") }
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

private fun failureMessage(failure: Failure): String = when (failure) {
    Failure.PrerequisiteFailure.BleUnsupported -> "Устройство не поддерживает BLE-сканирование."
    Failure.PrerequisiteFailure.BluetoothDisabled -> "Bluetooth выключен. Включите Bluetooth и повторите попытку."
    Failure.PrerequisiteFailure.PermissionsDenied -> AndroidPrerequisitesRepository.permissionDeniedMessage()
    Failure.PrerequisiteFailure.NoInternet -> "Нет подключения к интернету. Повторите попытку после восстановления сети."
    Failure.ScanFailure.Timeout -> "Терминал не найден за отведенное время."
    Failure.ScanFailure.HardwareError -> "BLE-сканирование недоступно на этом устройстве."
    Failure.ScanFailure.InvalidPacket -> "Получен некорректный BLE-пакет."
    is Failure.PaymentFailure -> paymentFailureMessage(failure)
}

private fun paymentFailureMessage(failure: Failure.PaymentFailure): String = when (failure) {
    Failure.PaymentFailure.Network -> "Не удалось отправить demo-платеж из-за сетевой ошибки."
    Failure.PaymentFailure.HostRejected -> "Хост отклонил demo-платеж."
    Failure.PaymentFailure.Serialization -> "Ответ сервера не удалось обработать."
    Failure.PaymentFailure.Unknown -> "Demo-платеж завершился неизвестной ошибкой."
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
