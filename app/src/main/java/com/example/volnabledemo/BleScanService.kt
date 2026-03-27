package com.example.volnabledemo

import android.R
import android.annotation.SuppressLint
import android.app.*
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.example.volnabledemo.data.ble.AndroidBleScanner
import com.example.volnabledemo.data.ble.AdvertisementPacketParser
import com.example.volnabledemo.data.ble.QrLinkBuilder
import com.example.volnabledemo.data.ble.ScanResponseParser
import com.example.volnabledemo.data.ble.SignalStrengthValidator
import com.example.volnabledemo.data.ble.VolnaCandidateAssembler
import com.example.volnabledemo.data.network.PaymentApi
import com.example.volnabledemo.data.repository.PaymentRepositoryImpl
import com.example.volnabledemo.domain.model.Outcome
import com.example.volnabledemo.domain.model.VolnaCandidate
import com.example.volnabledemo.domain.usecase.SubmitPaymentUseCase
import kotlinx.coroutines.*
import retrofit2.Retrofit
import retrofit2.converter.scalars.ScalarsConverterFactory
import java.text.NumberFormat
import java.util.Locale
import java.util.concurrent.atomic.AtomicBoolean

class BleScanService : Service() {

    companion object {
        const val NOTIFICATION_ID = 1001
        const val CHANNEL_ID = "ble_scan_channel"
        const val ACTION_START_SCAN = "START_SCAN"
        const val EXTRA_BACKGROUND_SCAN = "BACKGROUND_SCAN"

        const val PAY = "PAY"
        const val ACTION_STOP_SCAN = "STOP_SCAN"
        const val EXTRA_CANDIDATE = "candidate"
        const val EXTRA_QRC_ID = "qrc_id"
        const val EXTRA_QR_LINK = "qr_link"
        const val EXTRA_AMOUNT_MINOR = "amount_minor"
        const val EXTRA_MERCHANT_NAME = "merchant_name"
        const val EXTRA_RSSI = "rssi"
        const val EXTRA_RSSI_FINAL = "rssi_final"

        private const val BASE_URL = "https://beta-ecom.payment-guide.ru/"
    }

    private lateinit var bleScanner: AndroidBleScanner
    private lateinit var payUseCase: SubmitPaymentUseCase
    private var scanJob: Job? = null
    private val serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    // Флаги и кэш для предотвращения дубликатов
    private val notificationShown = AtomicBoolean(false)
    private val processedQrcIds = mutableSetOf<String>()
    private var lastNotificationTime = 0L
    private var lastProcessedQrcId: String? = null

    // Таймаут для блокировки повторных уведомлений (30 секунд)
    private val NOTIFICATION_COOLDOWN_MS = 30000L

    private val paymentReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            Log.d("BleScanService", "💳 Получен PAY в BroadcastReceiver")
            val bundle = intent.getBundleExtra(EXTRA_CANDIDATE)
            if (bundle != null) {
                Log.d("BleScanService", "Bundle получен, обрабатываем платеж")
                processPayment(bundle)
            } else {
                Log.e("BleScanService", "Bundle is null!")
            }
        }
    }

    @SuppressLint("UnspecifiedRegisterReceiverFlag")
    override fun onCreate() {
        super.onCreate()
        Log.d("BleScanService", "🟢 onCreate - сервис создан")

        // Инициализация PaymentApi и PaymentRepositoryImpl
        try {
            val retrofit = Retrofit.Builder()
                .baseUrl(BASE_URL)
                .addConverterFactory(ScalarsConverterFactory.create())
                .build()

            val paymentApi = retrofit.create(PaymentApi::class.java)
            val paymentRepository = PaymentRepositoryImpl(paymentApi)
            payUseCase = SubmitPaymentUseCase(paymentRepository)
            Log.d("BleScanService", "✅ payUseCase инициализирован")
        } catch (e: Exception) {
            Log.e("BleScanService", "❌ Ошибка инициализации payUseCase", e)
            stopSelf()
            return
        }

        createNotificationChannel()
        val filter = IntentFilter(PAY)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(paymentReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(paymentReceiver, filter)
        }
        Log.d("BleScanService", "BroadcastReceiver зарегистрирован для действия: $PAY")
        Log.d("BleScanService", "Receiver: $paymentReceiver")

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(NOTIFICATION_ID, createNotification(), ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
            Log.d("BleScanService", "startForeground вызван (Android 14+)")
        } else {
            startForeground(NOTIFICATION_ID, createNotification())
            Log.d("BleScanService", "startForeground вызван")
        }

        // Инициализация сканера
        bleScanner = AndroidBleScanner(
            context = this,
            advertisementPacketParser = AdvertisementPacketParser(),
            scanResponseParser = ScanResponseParser(),
            candidateAssembler = VolnaCandidateAssembler(
                SignalStrengthValidator(BuildConfig.RSSI_THRESHOLD),
                QrLinkBuilder(BuildConfig.SBP_PREFIX)
            )
        )
        Log.d("BleScanService", "bleScanner инициализирован")
    }

    private fun processPayment(bundle: Bundle) {
        Log.d("BleScanService", "🔄 Начинаем обработку платежа")

        val qrcId = bundle.getString(EXTRA_QRC_ID) ?: ""
        val qrLink = bundle.getString(EXTRA_QR_LINK) ?: ""
        val amountMinor = bundle.getLong(EXTRA_AMOUNT_MINOR, 0)
        val merchantName = bundle.getString(EXTRA_MERCHANT_NAME) ?: ""
        val rssi = bundle.getInt(EXTRA_RSSI, 0)
        val rssiFinal = bundle.getInt(EXTRA_RSSI_FINAL, 0)

        Log.d("BleScanService", "Платеж: магазин=$merchantName, сумма=${amountMinor / 100.0}")

        val candidate = VolnaCandidate(
            qrcId = qrcId,
            qrLink = qrLink,
            amountMinor = amountMinor,
            merchantName = merchantName,
            rssi = rssi,
            rssiFinal = rssiFinal
        )

        serviceScope.launch {
            try {
                Log.d("BleScanService", "=== НАЧАЛО ВЫЗОВА PAYMENT ===")
                Log.d("BleScanService", "candidate: ${candidate.merchantName}, сумма: ${candidate.amountMinor}")

                val result = payUseCase.invoke(candidate)

                Log.d("BleScanService", "=== РЕЗУЛЬТАТ ПОЛУЧЕН ===")
                Log.d("BleScanService", "result type: ${result.javaClass.simpleName}")
                Log.d("BleScanService", "result: $result")

                withContext(Dispatchers.Main) {
                    when (result) {
                        is Outcome.Success -> {
                            Log.d("BleScanService", "✅ ОПЛАТА УСПЕШНА! Показываем уведомление")
                            showPaymentResultNotification(true, merchantName, amountMinor)
                            Log.d("BleScanService", "✅ Уведомление должно быть показано")
                        }
                        is Outcome.FailureResult -> {
                            Log.e("BleScanService", "❌ ОШИБКА ОПЛАТЫ: ${result.reason}")
                            showPaymentResultNotification(false, merchantName, amountMinor)
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e("BleScanService", "Исключение при оплате", e)
                withContext(Dispatchers.Main) {
                    showPaymentResultNotification(false, merchantName, amountMinor)
                }
            }
        }
    }

    private fun showPaymentResultNotification(success: Boolean, merchantName: String?, amountMinor: Long) {
        val formattedAmount = NumberFormat.getCurrencyInstance(Locale("ru", "RU"))
            .format(amountMinor / 100.0)

        val title = if (success) "✅ Оплата успешна" else "❌ Ошибка оплаты"
        val message = if (success) {
            "Списано $formattedAmount в $merchantName"
        } else {
            "Не удалось оплатить $formattedAmount в $merchantName"
        }

        Log.d("BleScanService", "📢 Показываем уведомление о результате: $title")

        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            action = if (success) "PAYMENT_SUCCESS" else "PAYMENT_FAILED"
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(message)
            .setSmallIcon(R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()

        val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify((success).hashCode(), notification)

        Log.d("BleScanService", "Уведомление о результате отправлено")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("BleScanService", "onStartCommand, action: ${intent?.action}")
        Log.d("BleScanService", "Intent: $intent")
        if (intent != null) {
            Log.d("BleScanService", "Intent extras: ${intent.extras?.keySet()}")
        }

        when (intent?.action) {
            ACTION_START_SCAN -> {
                Log.d("BleScanService", "📡 Получен START_SCAN")
                startScanning()
            }
            ACTION_STOP_SCAN -> {
                Log.d("BleScanService", "🛑 Получен STOP_SCAN")
                stopScanning()
            }
            PAY -> {
                Log.d("BleScanService", "💳 Получен PAY в onStartCommand")
                val bundle = intent.getBundleExtra(EXTRA_CANDIDATE)
                if (bundle != null) {
                    Log.d("BleScanService", "Bundle получен, qrcId: ${bundle.getString(EXTRA_QRC_ID)}")
                    processPayment(bundle)
                } else {
                    Log.e("BleScanService", "Bundle is null in onStartCommand")
                }
            }
        }
        return START_STICKY
    }

    private fun startScanning() {
        if (scanJob?.isActive == true) {
            Log.d("BleScanService", "Сканирование уже активно")
            return
        }

        Log.d("BleScanService", "🔍 Запуск сканирования...")
        notificationShown.set(false)

        scanJob = serviceScope.launch {
            Log.d("BleScanService", "Корутина сканирования запущена")
            bleScanner.scanForCandidate().collect { result ->
                Log.d("BleScanService", "Получен результат сканирования")

                if (notificationShown.get()) {
                    Log.d("BleScanService", "⚠️ Уведомление уже показано, пропускаем")
                    return@collect
                }

                when (result) {
                    is Outcome.Success -> {
                        val candidate = result.value.candidate
                        val now = System.currentTimeMillis()

                        val isDuplicate = if (lastProcessedQrcId == candidate.qrcId) {
                            now - lastNotificationTime < NOTIFICATION_COOLDOWN_MS
                        } else {
                            false
                        }

                        if (!isDuplicate && !processedQrcIds.contains(candidate.qrcId)) {
                            processedQrcIds.add(candidate.qrcId)
                            lastProcessedQrcId = candidate.qrcId
                            lastNotificationTime = now
                            notificationShown.set(true)

                            Log.d("BleScanService", "✅ Новый кандидат: ${candidate.merchantName}, сумма: ${candidate.amountMinor}")
                            showPaymentNotification(candidate)
                            stopScanning()
                        } else {
                            Log.d("BleScanService", "⚠️ Пропускаем дубликат: ${candidate.qrcId}")
                        }
                    }
                    is Outcome.FailureResult -> {
                        Log.e("BleScanService", "❌ Ошибка сканирования: ${result.reason}")
                    }
                }
            }
        }
    }

    private fun stopScanning() {
        Log.d("BleScanService", "🛑 Остановка сканирования")
        scanJob?.cancel()
        scanJob = null
        Log.d("BleScanService", "Сканирование остановлено")
    }

    private fun showPaymentNotification(candidate: VolnaCandidate) {
        val formattedAmount = NumberFormat.getCurrencyInstance(Locale("ru", "RU"))
            .format(candidate.amountMinor / 100.0)
        Log.d("BleScanService", "📢 Показываем уведомление: $formattedAmount, магазин: ${candidate.merchantName}")

        val bundle = Bundle().apply {
            putString(EXTRA_QRC_ID, candidate.qrcId)
            putString(EXTRA_QR_LINK, candidate.qrLink)
            putLong(EXTRA_AMOUNT_MINOR, candidate.amountMinor)
            putString(EXTRA_MERCHANT_NAME, candidate.merchantName)
            putInt(EXTRA_RSSI, candidate.rssi)
            putInt(EXTRA_RSSI_FINAL, candidate.rssiFinal)
        }

        val intent = Intent(this, MainActivity::class.java).apply {
            Log.d("Ble", "PAYMENT FOUND@@@")
            action = "PAYMENT_FOUND"
            putExtra(EXTRA_CANDIDATE, bundle)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val payIntent = Intent(PAY).apply {
            Log.d("Ble", "PAYMENT CALLED - отправляем Broadcast")
            Log.d("Ble", "Action: $PAY")
            Log.d("Ble", "Extra: ${bundle.getString(EXTRA_QRC_ID)}")
            putExtra(EXTRA_CANDIDATE, bundle)
        }
        val payPendingIntent = PendingIntent.getBroadcast(
            this, 1, payIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Найден терминал Волна")
            .setContentText("Сумма: $formattedAmount, магазин: ${candidate.merchantName}")
            .setSmallIcon(R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .addAction(R.drawable.ic_menu_save, "Оплатить", payPendingIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()

        val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(candidate.hashCode(), notification)

        Log.d("BleScanService", "Уведомление отправлено")
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "BLE сканирование",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Уведомления о найденных терминалах Волна"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
            Log.d("BleScanService", "Канал уведомлений создан")
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Volna BLE сканирование")
            .setContentText("Сканирование активно")
            .setSmallIcon(R.drawable.ic_dialog_info)
            .build()
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d("BleScanService", "🔴 onDestroy - сервис уничтожен")
        stopScanning()
        notificationShown.set(false)
        processedQrcIds.clear()
        try {
            unregisterReceiver(paymentReceiver)
        } catch (e: Exception) {
            Log.e("BleScanService", "Ошибка при unregisterReceiver", e)
        }
        serviceScope.cancel()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}