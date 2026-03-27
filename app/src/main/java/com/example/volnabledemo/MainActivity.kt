package com.example.volnabledemo

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.Crossfade
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.volnabledemo.app.di.AppContainer
import com.example.volnabledemo.domain.error.Failure
import com.example.volnabledemo.domain.model.VolnaCandidate
import com.example.volnabledemo.platform.AndroidPrerequisitesRepository
import com.example.volnabledemo.presentation.PaymentFlowState
import com.example.volnabledemo.presentation.PaymentViewModel
import com.example.volnabledemo.ui.theme.VolnaBleDemoTheme
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.text.NumberFormat
import java.util.Locale
import kotlin.math.cos
import kotlin.math.sin
import com.example.volnabledemo.BleScanService.Companion.EXTRA_BACKGROUND_SCAN

private val BrandOrange = Color(0xFF176FC6)
private val BrandBlack = Color(0xFF000000)
private val BrandGray = Color(0xFFD7E6EA)
private val BrandLightGray = Color(0xFFE9F1F3)
private val BrandDarkGray = Color(0xFF2C2C2C)
private val BrandBlue = Color(0xFF176FC6)
private val BrandGreen = Color(0xFF27B648)
private val BrandRed = Color(0xFFEA002F)
private val White = Color(0xFFFFFFFF)
private val OverlayColor = Color(0xCCEBEBEB)

// Состояние для навигации между экранами
sealed class Screen {
    object Home : Screen()
    object Settings : Screen()
}

class MainActivity : ComponentActivity() {
    private val appContainer by lazy { AppContainer(this) }

    // Получаем SettingsDataStore через AppContainer
    private val settingsDataStore: SettingsDataStore
        get() = appContainer.settingsDataStore

    // Лаунчер для запроса BLE-разрешений
    private val blePermissionsLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { granted ->
        val allGranted = granted.values.all { it }
        android.util.Log.d("MainActivity", "BLE разрешения получены: $allGranted")
        if (allGranted) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                if (ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.ACCESS_BACKGROUND_LOCATION
                    ) != PackageManager.PERMISSION_GRANTED
                ) {
                    android.util.Log.d("MainActivity", "Теперь запрашиваем фоновое местоположение")
                    requestBackgroundLocationPermission()
                    return@registerForActivityResult
                }
            }
            lifecycleScope.launch {
                settingsDataStore.setBackgroundScanEnabled(true)
                startBleScanService(this@MainActivity, true)
                Toast.makeText(this@MainActivity, "Фоновое сканирование включено", Toast.LENGTH_SHORT).show()
            }
        } else {
            android.util.Log.d("MainActivity", "BLE разрешения отклонены")
            Toast.makeText(this, "Для фонового сканирования нужны разрешения Bluetooth", Toast.LENGTH_LONG).show()
            lifecycleScope.launch {
                settingsDataStore.setBackgroundScanEnabled(false)
            }
        }
    }

    // Лаунчер для запроса фонового разрешения
    private val backgroundLocationLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (isGranted) {
            android.util.Log.d("MainActivity", "Фоновое разрешение получено")
            lifecycleScope.launch {
                settingsDataStore.setBackgroundScanEnabled(true)
                startBleScanService(this@MainActivity, true)
                Toast.makeText(this@MainActivity, "Фоновое сканирование включено", Toast.LENGTH_SHORT).show()
            }
        } else {
            android.util.Log.d("MainActivity", "Фоновое разрешение отклонено")
            Toast.makeText(this, "Для фонового сканирования нужно разрешение на местоположение", Toast.LENGTH_LONG).show()
            lifecycleScope.launch {
                settingsDataStore.setBackgroundScanEnabled(false)
            }
        }
    }

    // Лаунчер для запроса разрешения на уведомления
    private val notificationPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        android.util.Log.d("MainActivity", "Notification permission granted: $isGranted")
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        requestNotificationPermission()

        setContent {
            VolnaBleDemoTheme {
                val viewModel: PaymentViewModel = viewModel(factory = appContainer.paymentViewModelFactory())
                val state by viewModel.state.collectAsState()

                var currentScreen by remember { mutableStateOf<Screen>(Screen.Home) }

                val permissionLauncher = rememberLauncherForActivityResult(
                    contract = ActivityResultContracts.RequestMultiplePermissions()
                ) { granted ->
                    if (granted.values.all { it }) {
                        viewModel.startScan()
                    } else {
                        viewModel.onPermissionsDenied()
                    }
                }

                LaunchedEffect(Unit) {
                    handleIntent(intent, viewModel)

                    settingsDataStore.getAutoScanOnStartupEnabled().collect { autoScanEnabled ->
                        if (autoScanEnabled && currentScreen == Screen.Home) {
                            android.util.Log.d("MainActivity", "Автосканирование включено, запускаем сканирование")
                            val hasPermissions = AndroidPrerequisitesRepository.requiredPermissions().all { permission ->
                                ContextCompat.checkSelfPermission(this@MainActivity, permission) == PackageManager.PERMISSION_GRANTED
                            }
                            if (hasPermissions) {
                                viewModel.startScan()
                            } else {
                                android.util.Log.d("MainActivity", "Нет разрешений для автосканирования")
                            }
                        }
                    }
                }

                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = Color.Transparent
                ) {
                    AppScreen(
                        state = state,
                        onStartScan = {
                            permissionLauncher.launch(
                                AndroidPrerequisitesRepository.requiredPermissions().toTypedArray()
                            )
                        },
                        onCancel = viewModel::reset,
                        onPay = viewModel::submitPayment,
                        onAcknowledgeSuccess = viewModel::acknowledgeSuccess,
                        currentScreen = currentScreen,
                        onNavigateToSettings = { currentScreen = Screen.Settings },
                        onBackFromSettings = { currentScreen = Screen.Home },
                        onRequestBackgroundLocationPermission = { requestBackgroundLocationPermission() },
                        onRequestPushAccess = { requestPushReceivingPermission() },
                        onRequestBlePermissions = { requestBlePermissions() }
                    )
                }
            }
        }

        lifecycleScope.launch {
            settingsDataStore.getBackgroundScanEnabled().collect { enabled ->
                android.util.Log.d("MainActivity", "Загружено состояние из DataStore: $enabled")
                if (enabled) {
                    if (hasBlePermissions(this@MainActivity)) {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            if (ContextCompat.checkSelfPermission(
                                    this@MainActivity,
                                    Manifest.permission.ACCESS_BACKGROUND_LOCATION
                                ) == PackageManager.PERMISSION_GRANTED
                            ) {
                                startBleScanService(this@MainActivity, true)
                            } else {
                                requestBackgroundLocationPermission()
                            }
                        } else {
                            startBleScanService(this@MainActivity, true)
                        }
                    } else {
                        requestBlePermissions()
                    }
                } else {
                    stopBleScanService(this@MainActivity)
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        handleIntent(intent, null)
    }

    private fun handleIntent(intent: Intent?, viewModel: PaymentViewModel?) {
        when (intent?.action) {
            "PAYMENT_FOUND", "PAYMENT_ACTION" -> {
                android.util.Log.d("MainActivity", "Получен Intent из уведомления: ${intent.action}")
                val bundle = intent.getBundleExtra(BleScanService.EXTRA_CANDIDATE)
                if (bundle != null) {
                    val candidate = VolnaCandidate(
                        qrcId = bundle.getString(BleScanService.EXTRA_QRC_ID) ?: "",
                        qrLink = bundle.getString(BleScanService.EXTRA_QR_LINK) ?: "",
                        amountMinor = bundle.getLong(BleScanService.EXTRA_AMOUNT_MINOR, 0),
                        merchantName = bundle.getString(BleScanService.EXTRA_MERCHANT_NAME) ?: "",
                        rssi = bundle.getInt(BleScanService.EXTRA_RSSI, 0),
                        rssiFinal = bundle.getInt(BleScanService.EXTRA_RSSI_FINAL, 0)
                    )
                    android.util.Log.d("MainActivity", "Кандидат получен: ${candidate.merchantName}, сумма: ${candidate.amountMinor}")
                    viewModel?.setCandidate(candidate)
                } else {
                    android.util.Log.e("MainActivity", "Bundle is null в handleIntent!")
                }
            }
            "PAYMENT_SUCCESS" -> {
                android.util.Log.d("MainActivity", "🎉 Получен PAYMENT_SUCCESS!")
                Toast.makeText(this, "Оплата успешна!", Toast.LENGTH_LONG).show()
            }
            "PAYMENT_FAILED" -> {
                android.util.Log.d("MainActivity", "❌ Получен PAYMENT_FAILED!")
                Toast.makeText(this, "Ошибка оплаты", Toast.LENGTH_LONG).show()
            }
        }
    }

    private fun requestBackgroundLocationPermission() {
        android.util.Log.d("MainActivity", "requestBackgroundLocationPermission вызван")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            if (ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.ACCESS_BACKGROUND_LOCATION
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                android.util.Log.d("MainActivity", "Запрашиваем ACCESS_BACKGROUND_LOCATION")
                backgroundLocationLauncher.launch(Manifest.permission.ACCESS_BACKGROUND_LOCATION)
            } else {
                android.util.Log.d("MainActivity", "Разрешение уже есть")
            }
        }
    }

    private fun requestBlePermissions() {
        android.util.Log.d("MainActivity", "requestBlePermissions вызван")
        val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            arrayOf(
                Manifest.permission.BLUETOOTH_SCAN,
                Manifest.permission.BLUETOOTH_CONNECT
            )
        } else {
            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)
        }
        blePermissionsLauncher.launch(permissions)
    }

    private fun requestPushReceivingPermission() {
        android.util.Log.d("MainActivity", "requestPushReceivingPermission вызван")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.POST_NOTIFICATIONS
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                notificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
            }
        }
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.POST_NOTIFICATIONS
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                android.util.Log.d("MainActivity", "Запрашиваем разрешение на уведомления")
                notificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
            }
        }
    }

    private fun hasBlePermissions(context: Context): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED &&
                    ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED
        } else {
            ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        }
    }
}

fun startBleScanService(context: Context, isBackground: Boolean = false) {
    android.util.Log.d("BleScanService", "startBleScanService вызван, isBackground=$isBackground")

    val hasBlePerm = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED &&
                ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED
    } else {
        ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
    }

    if (!hasBlePerm) {
        android.util.Log.e("BleScanService", "Нет BLE разрешений для запуска сервиса")
        return
    }

    val intent = Intent(context, BleScanService::class.java).apply {
        action = BleScanService.ACTION_START_SCAN
        putExtra(BleScanService.Companion.EXTRA_BACKGROUND_SCAN, isBackground)  // Используем Companion
    }
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        context.startForegroundService(intent)
        android.util.Log.d("BleScanService", "startForegroundService вызван")
    } else {
        context.startService(intent)
        android.util.Log.d("BleScanService", "startService вызван")
    }
}

fun stopBleScanService(context: Context) {
    android.util.Log.d("BleScanService", "stopBleScanService вызван")
    val intent = Intent(context, BleScanService::class.java).apply {
        action = BleScanService.ACTION_STOP_SCAN
    }
    context.stopService(intent)
    android.util.Log.d("BleScanService", "stopService вызван")
}

@Composable
private fun AppScreen(
    state: PaymentFlowState,
    onStartScan: () -> Unit,
    onCancel: () -> Unit,
    onPay: (VolnaCandidate) -> Unit,
    onAcknowledgeSuccess: () -> Unit,
    currentScreen: Screen,
    onNavigateToSettings: () -> Unit,
    onBackFromSettings: () -> Unit,
    onRequestBackgroundLocationPermission: () -> Unit,
    onRequestPushAccess: () -> Unit,
    onRequestBlePermissions: () -> Unit
) {
    Box(modifier = Modifier.fillMaxSize()) {
        AnimatedGradientBackground(modifier = Modifier.fillMaxSize())

        when (currentScreen) {
            Screen.Home -> {
                Crossfade(
                    targetState = state,
                    animationSpec = tween(240),
                    label = "main_crossfade"
                ) { currentState ->
                    when (currentState) {
                        PaymentFlowState.Idle -> HomeScreenContent(
                            onStartScan = onStartScan,
                            onNavigateToSettings = onNavigateToSettings
                        )
                        PaymentFlowState.CheckingPrerequisites,
                        PaymentFlowState.Scanning -> ScanningScreenContent(onCancel = onCancel)
                        is PaymentFlowState.ReadyForConfirmation -> PaymentConfirmScreenContent(
                            candidate = currentState.candidate,
                            onPay = onPay,
                            onCancel = onCancel
                        )
                        is PaymentFlowState.SubmittingPayment -> SubmittingPaymentScreenContent()
                        is PaymentFlowState.PaymentSuccess -> SuccessScreenContent(
                            candidate = currentState.candidate,
                            onDone = onAcknowledgeSuccess
                        )
                        is PaymentFlowState.PaymentError -> ErrorScreenContent(
                            title = "Ошибка оплаты",
                            message = paymentFailureMessage(currentState.failure),
                            onBack = onCancel
                        )
                        is PaymentFlowState.BlockingError -> ErrorScreenContent(
                            title = "Ошибка",
                            message = failureMessage(currentState.failure),
                            onBack = onCancel
                        )
                    }
                }
            }
            Screen.Settings -> SettingsScreen(
                onBack = onBackFromSettings,
                onRequestBackgroundLocationPermission = onRequestBackgroundLocationPermission,
                onRequestBlePermissions = onRequestBlePermissions,
                onRequestPushAccess = onRequestPushAccess
            )
        }
    }
}

@Composable
private fun HomeScreenContent(
    onStartScan: () -> Unit,
    onNavigateToSettings: () -> Unit
) {
    Box(modifier = Modifier.fillMaxSize()) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 28.dp, vertical = 22.dp)
                .statusBarsPadding()
                .navigationBarsPadding(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Spacer(modifier = Modifier.height(32.dp))

            Text(
                text = "Добро пожаловать!",
                fontSize = 24.sp,
                lineHeight = 32.sp,
                fontWeight = FontWeight.Black,
                color = BrandBlack,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = "Это приложение для оплаты QR-кодов\nпо технологии Bluetooth Low Energy",
                fontSize = 14.sp,
                lineHeight = 20.sp,
                fontWeight = FontWeight.Normal,
                color = BrandDarkGray,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(32.dp))

            WaveCircle(
                coreColor = BrandOrange,
                waveColor = BrandBlue,
                onClick = onStartScan,
                content = {
                    Icon(
                        painter = painterResource(id = R.drawable.bt_icon),
                        contentDescription = "Bluetooth",
                        modifier = Modifier.size(52.dp),
                        tint = White
                    )
                }
            )

            Spacer(modifier = Modifier.height(64.dp))

            Text(
                text = "Нажмите на кнопку Bluetooth\nдля начала сканирования",
                fontSize = 14.sp,
                lineHeight = 24.sp,
                fontWeight = FontWeight.Normal,
                color = BrandBlack,
                textAlign = TextAlign.Center
            )
        }

        IconButton(
            onClick = onNavigateToSettings,
            modifier = Modifier
                .align(Alignment.TopEnd)
                .padding(16.dp)
        ) {
            Icon(
                imageVector = Icons.Default.Settings,
                contentDescription = "Настройки",
                tint = BrandBlack
            )
        }
    }
}

@Composable
private fun ScanningScreenContent(
    onCancel: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .statusBarsPadding()
            .navigationBarsPadding()
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 28.dp, vertical = 22.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                text = "Пожалуйста, подождите",
                fontSize = 24.sp,
                lineHeight = 32.sp,
                fontWeight = FontWeight.Black,
                color = BrandBlack,
                textAlign = TextAlign.Center,
                maxLines = 1
            )

            Spacer(modifier = Modifier.height(64.dp))

            WaveCircle(
                coreColor = BrandBlue,
                waveColor = BrandBlue,
                showOrbitDots = true,
                onClick = {},
                content = {}
            )

            Spacer(modifier = Modifier.height(64.dp))

            Text(
                text = "Сканирование...",
                fontSize = 14.sp,
                letterSpacing = 0.8.sp,
                fontWeight = FontWeight.Normal,
                color = BrandBlack,
                textAlign = TextAlign.Center
            )
        }

        Button(
            onClick = onCancel,
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .padding(horizontal = 28.dp, vertical = 18.dp)
                .height(64.dp),
            shape = RoundedCornerShape(32.dp),
            colors = ButtonDefaults.buttonColors(containerColor = BrandOrange)
        ) {
            Text(
                text = "Отмена",
                fontSize = 16.sp,
                fontWeight = FontWeight.Medium,
                color = White
            )
        }
    }
}

@Composable
private fun SubmittingPaymentScreenContent() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 28.dp, vertical = 22.dp)
            .statusBarsPadding()
            .navigationBarsPadding(),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Text(
            text = "Пожалуйста, подождите",
            fontSize = 24.sp,
            lineHeight = 32.sp,
            fontWeight = FontWeight.Black,
            color = BrandBlack,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(64.dp))

        WaveCircle(
            coreColor = BrandOrange,
            waveColor = BrandGray,
            showOrbitDots = true,
            content = {
                CircularProgressIndicator(
                    modifier = Modifier.size(44.dp),
                    color = BrandOrange,
                    strokeWidth = 3.dp
                )
            },
            onClick = {}
        )

        Spacer(modifier = Modifier.height(64.dp))

        Text(
            text = "отправка платежа...",
            fontSize = 14.sp,
            letterSpacing = 0.8.sp,
            fontWeight = FontWeight.Normal,
            color = BrandBlack,
            textAlign = TextAlign.Center
        )
    }
}

@Composable
private fun PaymentConfirmScreenContent(
    candidate: VolnaCandidate,
    onPay: (VolnaCandidate) -> Unit,
    onCancel: () -> Unit
) {
    val formattedAmount = formatAmount(candidate.amountMinor)

    Box(
        modifier = Modifier
            .fillMaxSize()
            .statusBarsPadding()
            .navigationBarsPadding()
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 28.dp, vertical = 18.dp)
                .padding(bottom = 112.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier
                    .padding(vertical = 12.dp)
            ) {
                IconButton(
                    modifier = Modifier.size(28.dp),
                    onClick = onCancel,
                ) {
                    Icon(imageVector = Icons.Default.ArrowBack, contentDescription = null, tint = BrandBlack)
                }

                Spacer(modifier = Modifier.width(16.dp))

                Text(
                    text = "Оплатить",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = BrandBlack
                )
            }

            Spacer(modifier = Modifier.height(40.dp))

            ConfirmSection(label = "Магазин", value = candidate.merchantName.ifBlank { "—" })
            Spacer(modifier = Modifier.height(28.dp))

            ConfirmSection(label = "Сумма", value = formattedAmount)
            Spacer(modifier = Modifier.height(28.dp))

            ConfirmSection(label = "QR link", value = candidate.qrLink)
            Spacer(modifier = Modifier.height(28.dp))

            ConfirmSection(label = "QRC ID", value = candidate.qrcId)
        }

        PrimaryButton(
            text = "Оплатить $formattedAmount",
            onClick = { onPay(candidate) },
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(horizontal = 28.dp, vertical = 18.dp)
        )
    }
}

@Composable
private fun SuccessScreenContent(
    candidate: VolnaCandidate,
    onDone: () -> Unit
) {
    val formattedAmount = formatAmount(candidate.amountMinor)
    var progress by remember { mutableFloatStateOf(0f) }
    val timeoutDuration = 10000L

    LaunchedEffect(Unit) {
        val startTime = System.currentTimeMillis()
        while (true) {
            val elapsed = System.currentTimeMillis() - startTime
            if (elapsed >= timeoutDuration) {
                progress = 1f
                onDone()
                break
            }
            progress = elapsed.toFloat() / timeoutDuration.toFloat()
            delay(16)
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .statusBarsPadding()
            .navigationBarsPadding()
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 28.dp, vertical = 22.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                text = "Одобрено",
                fontSize = 24.sp,
                lineHeight = 32.sp,
                fontWeight = FontWeight.Black,
                color = BrandGreen,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(64.dp))

            WaveCircle(
                coreColor = BrandGreen,
                waveColor = BrandGreen,
                onClick = {},
                content = {
                    Icon(
                        imageVector = Icons.Default.Check,
                        contentDescription = "Успех",
                        modifier = Modifier.size(52.dp),
                        tint = White
                    )
                }
            )

            Spacer(modifier = Modifier.height(64.dp))

            Text(
                text = "оплата",
                fontSize = 16.sp,
                letterSpacing = 0.8.sp,
                fontWeight = FontWeight.Normal,
                color = BrandDarkGray,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = formattedAmount,
                fontSize = 24.sp,
                lineHeight = 32.sp,
                fontWeight = FontWeight.Black,
                color = BrandBlack,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(24.dp))

            LinearProgressIndicator(
                progress = progress,
                modifier = Modifier
                    .fillMaxWidth(0.6f)
                    .height(4.dp)
                    .clip(RoundedCornerShape(2.dp)),
                color = BrandGreen,
                trackColor = Color(0xFFE0E0E0)
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "Возврат на главный экран...",
                fontSize = 12.sp,
                color = BrandDarkGray
            )
        }
    }
}

@Composable
private fun ErrorScreenContent(
    title: String,
    message: String,
    onBack: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .statusBarsPadding()
            .navigationBarsPadding()
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 28.dp, vertical = 22.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                text = title,
                fontSize = 24.sp,
                lineHeight = 32.sp,
                fontWeight = FontWeight.Black,
                color = BrandRed,
                textAlign = TextAlign.Center,
                maxLines = 1
            )

            Spacer(modifier = Modifier.height(64.dp))

            WaveCircle(
                coreColor = BrandRed,
                waveColor = BrandRed,
                showOrbitDots = false,
                content = {
                    Text(
                        text = "!",
                        fontSize = 48.sp,
                        fontWeight = FontWeight.Bold,
                        color = White
                    )
                },
                onClick = {}
            )

            Spacer(modifier = Modifier.height(64.dp))

            Text(
                text = message,
                fontSize = 14.sp,
                lineHeight = 24.sp,
                fontWeight = FontWeight.Normal,
                color = BrandBlack,
                textAlign = TextAlign.Center
            )
        }

        PrimaryButton(
            text = "На главный экран",
            onClick = onBack,
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(horizontal = 28.dp, vertical = 18.dp)
        )
    }
}

@Composable
private fun PrimaryButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Button(
        onClick = onClick,
        modifier = modifier
            .fillMaxWidth()
            .height(64.dp),
        shape = RoundedCornerShape(32.dp),
        colors = ButtonDefaults.buttonColors(containerColor = BrandOrange)
    ) {
        Text(
            text = text,
            fontSize = 14.sp,
            fontWeight = FontWeight.Medium,
            color = White
        )
    }
}

@Composable
private fun ConfirmSection(
    label: String,
    value: String
) {
    Column(modifier = Modifier.fillMaxWidth()) {
        Text(
            text = label,
            fontSize = 14.sp,
            fontWeight = FontWeight.Normal,
            color = BrandOrange
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = value,
            fontSize = 24.sp,
            lineHeight = 30.sp,
            fontWeight = FontWeight.Black,
            color = BrandBlack,
            maxLines = 4,
            overflow = TextOverflow.Ellipsis
        )
    }
}

@Composable
private fun WaveCircle(
    coreColor: Color,
    waveColor: Color,
    showOrbitDots: Boolean = false,
    onClick: () -> Unit,
    content: @Composable BoxScope.() -> Unit
) {
    val infinite = rememberInfiniteTransition(label = "waves")

    val wave1 by infinite.animateFloat(
        initialValue = 0.92f,
        targetValue = 1.10f,
        animationSpec = infiniteRepeatable(
            animation = tween(2300, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "wave1"
    )

    val wave2 by infinite.animateFloat(
        initialValue = 1.10f,
        targetValue = 1.33f,
        animationSpec = infiniteRepeatable(
            animation = tween(2900, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "wave2"
    )

    val orbitAngle by infinite.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(
            animation = tween(2600, easing = LinearEasing)
        ),
        label = "orbit"
    )

    Box(
        modifier = Modifier
            .size(270.dp)
            .clip(CircleShape)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Canvas(
            modifier = Modifier.fillMaxSize(),
            onDraw = {
                val center = Offset(size.width / 2f, size.height / 2f)
                val baseRadius = size.minDimension * 0.20f

                val wave1Radius = baseRadius * wave1 * 1.75f
                val wave2Radius = baseRadius * wave2 * 2.28f

                drawCircle(
                    color = waveColor.copy(alpha = 0.50f),
                    radius = wave1Radius,
                    center = center,
                    style = Stroke(width = 2.4.dp.toPx())
                )

                drawCircle(
                    color = waveColor.copy(alpha = 0.46f),
                    radius = wave2Radius,
                    center = center,
                    style = Stroke(width = 1.8.dp.toPx())
                )

                if (showOrbitDots) {
                    val orbitRadius = baseRadius * 1.72f
                    val angles = listOf(
                        orbitAngle,
                        orbitAngle + 120f,
                        orbitAngle + 240f
                    )

                    val radii = listOf(5.dp.toPx(), 4.dp.toPx(), 3.dp.toPx())
                    val alphas = listOf(0.95f, 0.65f, 0.45f)

                    angles.forEachIndexed { index, deg ->
                        val rad = Math.toRadians(deg.toDouble())
                        val point = Offset(
                            x = center.x + cos(rad).toFloat() * orbitRadius,
                            y = center.y + sin(rad).toFloat() * orbitRadius
                        )
                        drawCircle(
                            color = waveColor.copy(alpha = alphas[index]),
                            radius = radii[index],
                            center = point
                        )
                    }
                }
            }
        )

        Box(
            modifier = Modifier
                .size(116.dp)
                .background(coreColor, CircleShape),
            contentAlignment = Alignment.Center,
            content = content
        )
    }
}

private fun formatAmount(amountMinor: Long): String {
    val currency = NumberFormat.getCurrencyInstance(Locale("ru", "RU"))
    return currency.format(amountMinor / 100.0)
}

private fun failureMessage(failure: Failure): String = when (failure) {
    Failure.PrerequisiteFailure.BleUnsupported ->
        "Устройство не поддерживает BLE-сканирование."

    Failure.PrerequisiteFailure.BluetoothDisabled ->
        "Bluetooth выключен. Включите Bluetooth и повторите попытку."

    Failure.PrerequisiteFailure.PermissionsDenied ->
        AndroidPrerequisitesRepository.permissionDeniedMessage()

    Failure.PrerequisiteFailure.NoInternet ->
        "Нет подключения к интернету. Повторите попытку после восстановления сети."

    Failure.ScanFailure.Timeout ->
        "BLE пакет не найден."

    Failure.ScanFailure.HardwareError ->
        "BLE-сканирование недоступно на этом устройстве."

    Failure.ScanFailure.InvalidPacket ->
        "Получен некорректный BLE-пакет."

    is Failure.PaymentFailure ->
        paymentFailureMessage(failure)
}

private fun paymentFailureMessage(failure: Failure.PaymentFailure): String = when (failure) {
    Failure.PaymentFailure.Network ->
        "Не удалось отправить платёж из-за сетевой ошибки или таймаута."

    Failure.PaymentFailure.HostRejected ->
        "Хост отклонил платёж."

    Failure.PaymentFailure.Serialization ->
        "Ответ сервера не удалось обработать."

    Failure.PaymentFailure.Unknown ->
        "Платёж завершился неизвестной ошибкой."
}