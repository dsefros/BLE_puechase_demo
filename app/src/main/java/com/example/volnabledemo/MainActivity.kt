package com.example.volnabledemo

import android.os.Bundle
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
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.volnabledemo.app.di.AppContainer
import com.example.volnabledemo.domain.error.Failure
import com.example.volnabledemo.domain.model.VolnaCandidate
import com.example.volnabledemo.platform.AndroidPrerequisitesRepository
import com.example.volnabledemo.presentation.PaymentFlowState
import com.example.volnabledemo.presentation.PaymentViewModel
import com.example.volnabledemo.ui.theme.VolnaBleDemoTheme
import kotlinx.coroutines.delay
import java.text.NumberFormat
import java.util.Locale
import kotlin.math.cos
import kotlin.math.sin

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
                    if (granted.values.all { it }) {
                        viewModel.startScan()
                    } else {
                        viewModel.onPermissionsDenied()
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
    Box(modifier = Modifier.fillMaxSize()) {
        // Анимированный градиентный фон
        AnimatedGradientBackground(modifier = Modifier.fillMaxSize())

        // Оверлей закомментирован для лучшей видимости анимации
        // Box(
        //     modifier = Modifier
        //         .fillMaxSize()
        //         .background(OverlayColor)
        //         .blur(10.dp)
        // )

        Crossfade(
            targetState = state,
            animationSpec = tween(240),
            label = "main_crossfade"
        ) { currentState ->
            when (currentState) {
                PaymentFlowState.Idle -> HomeScreenContent(onStartScan = onStartScan)

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
}

@Composable
private fun HomeScreenContent(
    onStartScan: () -> Unit
) {
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
    val timeoutDuration = 10000L // 10 секунд

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