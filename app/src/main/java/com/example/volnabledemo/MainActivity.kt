package com.example.volnabledemo


import android.os.Bundle
import androidx.compose.material3.Icon
import androidx.compose.ui.res.painterResource
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.Icon
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
import androidx.compose.foundation.layout.ColumnScope
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
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
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
private val ScreenBg = Color(0xCCEBEBEB)
private val White = Color(0xFFFFFFFF)

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
                    color = ScreenBg
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
    Crossfade(
        targetState = state,
        animationSpec = tween(240),
        label = "main_crossfade"
    ) { currentState ->
        when (currentState) {
            PaymentFlowState.Idle -> HomeScreen(onStartScan = onStartScan)

            PaymentFlowState.CheckingPrerequisites,
            PaymentFlowState.Scanning -> ScanningScreen(onCancel = onCancel)

            is PaymentFlowState.ReadyForConfirmation -> PaymentConfirmScreen(
                candidate = currentState.candidate,
                onPay = onPay,
                onCancel = onCancel
            )

            is PaymentFlowState.SubmittingPayment -> SubmittingPaymentScreen()

            is PaymentFlowState.PaymentSuccess -> SuccessScreen(
                candidate = currentState.candidate,
                onDone = onAcknowledgeSuccess
            )

            is PaymentFlowState.PaymentError -> ErrorScreen(
                title = "Ошибка оплаты",
                message = paymentFailureMessage(currentState.failure),
                onBack = onCancel
            )

            is PaymentFlowState.BlockingError -> ErrorScreen(
                title = "Ошибка",
                message = failureMessage(currentState.failure),
                onBack = onCancel
            )
        }
    }
}

@Composable
private fun HomeScreen(
    onStartScan: () -> Unit
) {
    BrandScreen(showTopo = true) {
        Spacer(modifier = Modifier.height(32.dp))

        Text(
            text = "Добро пожаловать!",
            fontSize = 24.sp,
            lineHeight = 32.sp,
            fontWeight = FontWeight.Black,
            color = BrandBlack,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(64.dp))

        // Кнопка сканирования - кликабельный оранжевый круг с иконкой Bluetooth
        WaveCircle(
            coreColor = BrandOrange,
            waveColor = BrandBlue,
            onClick = onStartScan,
            content = {
                Icon(
                    painter = painterResource(id = R.drawable.bt_icon), // имя вашего файла без расширения
                    contentDescription = "Bluetooth",
                    modifier = Modifier.size(52.dp),
                    tint = White
                )
            }
        )

        Spacer(modifier = Modifier.height(64.dp))

        Text(
            text = "Нажмите на кнопку Bluetooth\nдля начала сканирования",
            fontSize = 16.sp,
            lineHeight = 24.sp,
            fontWeight = FontWeight.Normal,
            color = BrandBlack,
            textAlign = TextAlign.Center
        )
    }
}

@Composable
private fun ScanningScreen(
    onCancel: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(ScreenBg)
            .statusBarsPadding()
            .navigationBarsPadding()
    ) {
        // Фоновые элементы
        TopoBackground(
            modifier = Modifier
                .fillMaxSize()
                .alpha(0.28f)
        )

        // Основной контент по центру
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
                content = {
                },
                onClick = {}
            )

            Spacer(modifier = Modifier.height(42.dp))

            Text(
                text = "сканирование...",
                fontSize = 16.sp,
                letterSpacing = 0.8.sp,
                fontWeight = FontWeight.Normal,
                color = BrandBlack,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(32.dp))

            Text(
                text = "Поиск может занять до 10 секунд",
                fontSize = 14.sp,
                lineHeight = 20.sp,
                fontWeight = FontWeight.Normal,
                color = BrandDarkGray,
                textAlign = TextAlign.Center
            )
        }

        // Кнопка отмены внизу экрана (как на HomeScreen)
        PrimaryButton(
            text = "Отмена",
            onClick = onCancel,
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(horizontal = 28.dp, vertical = 18.dp)
        )
    }
}

@Composable
private fun SubmittingPaymentScreen() {
    BrandScreen(showTopo = true) {
        Text(
            text = "Подождите, пожалуйста",
            fontSize = 24.sp,
            lineHeight = 32.sp,
            fontWeight = FontWeight.Black,
            color = BrandBlack,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(40.dp))

        WaveCircle(
            coreColor = BrandOrange,
            waveColor = BrandGray,
            showOrbitDots = true,
            content = {
                CircularProgressIndicator(
                    modifier = Modifier.size(44.dp),
                    color = White,
                    strokeWidth = 3.dp
                )
            },
            onClick = {}
        )

        Spacer(modifier = Modifier.height(42.dp))

        Text(
            text = "отправка платежа...",
            fontSize = 18.sp,
            letterSpacing = 0.8.sp,
            fontWeight = FontWeight.Normal,
            color = BrandBlack,
            textAlign = TextAlign.Center
        )
    }
}

@Composable
private fun PaymentConfirmScreen(
    candidate: VolnaCandidate,
    onPay: (VolnaCandidate) -> Unit,
    onCancel: () -> Unit
) {
    val formattedAmount = formatAmount(candidate.amountMinor)

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(ScreenBg)
            .statusBarsPadding()
            .navigationBarsPadding()
    ) {
        TopoBackground(
            modifier = Modifier
                .fillMaxSize()
                .alpha(0.28f)
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 28.dp, vertical = 18.dp)
                .padding(bottom = 112.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier
                    .padding(vertical = 12.dp)  // увеличивает область нажатия
            ) {
                IconButton(
                    modifier = Modifier.size(28.dp),
                    onClick = onCancel,
                ) {
                    Icon(  imageVector = Icons.Default.ArrowBack, contentDescription = null)
                }

                Spacer(modifier = Modifier.width(16.dp))

                Text(
                    text = "Оплатить",
                    fontSize = 24.sp,
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
private fun SuccessScreen(
    candidate: VolnaCandidate,
    onDone: () -> Unit
) {
    val formattedAmount = formatAmount(candidate.amountMinor)

    LaunchedEffect(Unit) {
        delay(1800)
        onDone()
    }

    BrandScreen(showTopo = true) {
        Text(
            text = "Одобрено",
            fontSize = 30.sp,
            lineHeight = 34.sp,
            fontWeight = FontWeight.Black,
            color = BrandGreen,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(40.dp))

        WaveCircle(
            coreColor = BrandGreen,
            waveColor = BrandGray,
            content = {
                Text(
                    text = "✓",
                    fontSize = 54.sp,
                    fontWeight = FontWeight.Bold,
                    color = White
                )
            },
            onClick = {}
        )

        Spacer(modifier = Modifier.height(40.dp))

        Text(
            text = "оплата",
            fontSize = 18.sp,
            letterSpacing = 0.8.sp,
            fontWeight = FontWeight.Normal,
            color = BrandDarkGray,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(10.dp))

        Text(
            text = formattedAmount,
            fontSize = 30.sp,
            lineHeight = 34.sp,
            fontWeight = FontWeight.Black,
            color = BrandBlack,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = candidate.merchantName,
            fontSize = 15.sp,
            lineHeight = 21.sp,
            fontWeight = FontWeight.Normal,
            color = BrandDarkGray,
            textAlign = TextAlign.Center,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis
        )
    }
}

@Composable
private fun ErrorScreen(
    title: String,
    message: String,
    onBack: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(ScreenBg)
            .statusBarsPadding()
            .navigationBarsPadding()
    ) {
        TopoBackground(
            modifier = Modifier
                .fillMaxSize()
                .alpha(0.28f)
        )

        // Основной контент по центру
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 28.dp, vertical = 22.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                text = title,
                fontSize = 30.sp,
                lineHeight = 34.sp,
                fontWeight = FontWeight.Black,
                color = BrandRed,
                textAlign = TextAlign.Center
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

            Spacer(modifier = Modifier.height(42.dp))

            Text(
                text = message,
                fontSize = 17.sp,
                lineHeight = 24.sp,
                fontWeight = FontWeight.Normal,
                color = BrandBlack,
                textAlign = TextAlign.Center
            )
        }

        // Кнопка внизу экрана
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
private fun BrandScreen(
    showTopo: Boolean,
    content: @Composable ColumnScope.() -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(ScreenBg)
            .statusBarsPadding()
            .navigationBarsPadding()
    ) {
        if (showTopo) {
            TopoBackground(
                modifier = Modifier
                    .fillMaxSize()
                    .alpha(0.42f)
            )
        }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 28.dp, vertical = 22.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
            content = content
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
            fontSize = 19.sp,
            fontWeight = FontWeight.Medium,
            color = White
        )
    }
}

@Composable
private fun SecondaryButton(
    text: String,
    onClick: () -> Unit
) {
    Button(
        onClick = onClick,
        modifier = Modifier
            .fillMaxWidth()
            .height(56.dp),
        shape = RoundedCornerShape(28.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = Color.Transparent,
            contentColor = BrandOrange
        ),
        elevation = null
    ) {
        Text(
            text = text,
            fontSize = 17.sp,
            fontWeight = FontWeight.Medium,
            color = BrandOrange
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
private fun SomersWordmark() {
    Row(
        verticalAlignment = Alignment.CenterVertically
    ) {
        SomersMark(modifier = Modifier.size(22.dp))
        Spacer(modifier = Modifier.width(10.dp))
        Text(
            text = "somers",
            fontSize = 22.sp,
            fontWeight = FontWeight.Black,
            color = BrandBlack
        )
    }
}

@Composable
private fun SomersMark(
    modifier: Modifier = Modifier
) {
    Canvas(modifier = modifier) {
        val center = Offset(size.width / 2f, size.height / 2f)
        val innerGap = size.minDimension * 0.16f
        val outer = size.minDimension * 0.47f
        val stroke = size.minDimension * 0.11f

        for (i in 0 until 8) {
            val angle = Math.toRadians((i * 45.0) - 90.0)
            val sx = center.x + cos(angle).toFloat() * innerGap
            val sy = center.y + sin(angle).toFloat() * innerGap
            val ex = center.x + cos(angle).toFloat() * outer
            val ey = center.y + sin(angle).toFloat() * outer

            drawLine(
                color = BrandOrange,
                start = Offset(sx, sy),
                end = Offset(ex, ey),
                strokeWidth = stroke,
                cap = StrokeCap.Square
            )
        }
    }
}

@Composable
private fun WaveCircle(
    coreColor: Color,
    waveColor: Color,
    showOrbitDots: Boolean = false,
    onClick: (() -> Unit),
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
        Canvas(modifier = Modifier.fillMaxSize()) {
            val center = Offset(size.width / 2f, size.height / 2f)
            val baseRadius = size.minDimension * 0.20f

            drawCircle(
                color = waveColor.copy(alpha = 0.50f),
                radius = baseRadius * wave1 * 1.75f,
                center = center,
                style = Stroke(width = 2.4.dp.toPx())
            )

            drawCircle(
                color = waveColor.copy(alpha = 0.46f),
                radius = baseRadius * wave2 * 2.28f,
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

        Box(
            modifier = Modifier
                .size(116.dp)
                .background(coreColor, CircleShape),
            contentAlignment = Alignment.Center,
            content = content
        )
    }
}

@Composable
private fun TopoBackground(
    modifier: Modifier = Modifier
) {
    Canvas(modifier = modifier) {
        val major = BrandGray.copy(alpha = 0.52f)
        val minor = BrandGray.copy(alpha = 0.20f)

        fun contourPath(
            cx: Float,
            cy: Float,
            rx: Float,
            ry: Float,
            wobble: Float,
            phase: Float
        ): Path {
            val path = Path()
            val steps = 180
            for (i in 0..steps) {
                val t = (i.toFloat() / steps.toFloat()) * (Math.PI * 2.0)
                val x = (
                        cx +
                                ((rx + (sin(t * 3.0 + phase.toDouble()) * wobble).toFloat()) *
                                        cos(t).toFloat())
                        )

                val y = (
                        cy +
                                ((ry + (cos(t * 4.0 + phase.toDouble()) * wobble * 0.85).toFloat()) *
                                        sin(t).toFloat())
                        )

                if (i == 0) path.moveTo(x, y) else path.lineTo(x, y)
            }
            path.close()
            return path
        }

        val clusters = listOf(
            listOf(size.width * 0.18f, size.height * 0.26f, 170f, 145f),
            listOf(size.width * 0.55f, size.height * 0.18f, 220f, 120f),
            listOf(size.width * 0.78f, size.height * 0.36f, 210f, 165f),
            listOf(size.width * 0.36f, size.height * 0.52f, 180f, 145f),
            listOf(size.width * 0.80f, size.height * 0.78f, 260f, 235f),
            listOf(size.width * 0.42f, size.height * 0.90f, 220f, 180f)
        )

        clusters.forEachIndexed { clusterIndex, raw ->
            val cx = raw[0]
            val cy = raw[1]
            val rx = raw[2]
            val ry = raw[3]

            for (level in 0 until 14) {
                val scale = 1f - level * 0.058f
                if (scale <= 0f) continue

                val path = contourPath(
                    cx = cx,
                    cy = cy,
                    rx = rx * scale,
                    ry = ry * scale,
                    wobble = 7.5f * scale,
                    phase = clusterIndex * 0.7f + level * 0.24f
                )

                drawPath(
                    path = path,
                    color = if (level % 5 == 0) major else minor,
                    style = Stroke(width = if (level % 5 == 0) 1.25.dp.toPx() else 0.75.dp.toPx())
                )
            }
        }
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