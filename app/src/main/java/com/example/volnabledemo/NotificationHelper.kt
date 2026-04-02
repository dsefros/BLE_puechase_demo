package com.example.volnabledemo

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.example.volnabledemo.domain.model.VolnaCandidate
import java.text.NumberFormat
import java.util.Locale

/**
 * Хелпер для управления push-уведомлениями
 */
object NotificationHelper {

    // Константы
    private const val CHANNEL_ID = "volna_payments"
    private const val CHANNEL_NAME = "Volna Payments"
    private const val NOTIFICATION_ID_CANDIDATE = 1001
    private const val NOTIFICATION_ID_SUCCESS = 1002
    private const val NOTIFICATION_ID_ERROR = 1003

    /**
     * Создание канала уведомлений (для Android 8+)
     */
    fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Уведомления о найденных терминалах и оплатах"
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 500, 200, 500)
                setShowBadge(true)
            }
            val notificationManager = context.getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    /**
     * Уведомление о найденном терминале
     */
    fun showCandidateNotification(context: Context, candidate: VolnaCandidate) {
        val notificationManager = context.getSystemService(NotificationManager::class.java)

        val formattedAmount = NumberFormat.getCurrencyInstance(Locale("ru", "RU"))
            .format(candidate.amountMinor / 100.0)


        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setContentTitle("Найден терминал Волна")
            .setContentText("Сумма: $formattedAmount, магазин: ${candidate.merchantName}")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()

        notificationManager.notify(NOTIFICATION_ID_CANDIDATE, notification)
    }

    /**
     * Уведомление об успешной оплате
     */
    fun showSuccessNotification(context: Context, candidate: VolnaCandidate) {
        val notificationManager = context.getSystemService(NotificationManager::class.java)

        val formattedAmount = NumberFormat.getCurrencyInstance(Locale("ru", "RU"))
            .format(candidate.amountMinor / 100.0)


        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setContentTitle("✅ Оплата успешна")
            .setContentText("Списано $formattedAmount в магазине ${candidate.merchantName}")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()

        notificationManager.notify(NOTIFICATION_ID_SUCCESS, notification)
    }

    /**
     * Уведомление об ошибке оплаты
     */
    fun showErrorNotification(context: Context, merchantName: String, amountMinor: Long, errorMessage: String) {
        val notificationManager = context.getSystemService(NotificationManager::class.java)

        val formattedAmount = NumberFormat.getCurrencyInstance(Locale("ru", "RU"))
            .format(amountMinor / 100.0)

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setContentTitle("❌ Ошибка оплаты")
            .setContentText("Не удалось списать $formattedAmount в магазине $merchantName: $errorMessage")
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()

        notificationManager.notify(NOTIFICATION_ID_ERROR, notification)
    }

    /**
     * Отмена всех уведомлений
     */
    fun cancelAllNotifications(context: Context) {
        val notificationManager = context.getSystemService(NotificationManager::class.java)
        notificationManager.cancelAll()
    }

    /**
     * Отмена конкретного уведомления
     */
    fun cancelNotification(context: Context, notificationId: Int) {
        val notificationManager = context.getSystemService(NotificationManager::class.java)
        notificationManager.cancel(notificationId)
    }
}