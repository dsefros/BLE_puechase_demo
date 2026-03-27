package com.example.volnabledemo

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import kotlinx.coroutines.launch

// Изменяем имя extension property, чтобы избежать конфликта
private val Context.settingsStore: SettingsDataStore
    get() = SettingsDataStore(this)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onBack: () -> Unit,
    onRequestBackgroundLocationPermission: () -> Unit = {},
    onRequestBlePermissions: () -> Unit = {},
    onRequestPushAccess: () -> Unit = {}
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val dataStore = context.settingsStore  // Используем settingsStore

    var isBackgroundScanEnabled by remember { mutableStateOf(false) }
    var isAutoScanOnStartupEnabled by remember { mutableStateOf(false) }
    var isLoading by remember { mutableStateOf(true) }
    var showPermissionDialog by remember { mutableStateOf(false) }
    var showBlePermissionDialog by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        dataStore.getBackgroundScanEnabled().collect { enabled ->
            android.util.Log.d("SettingsScreen", "Загружено состояние фонового сканирования: $enabled")
            isBackgroundScanEnabled = enabled
            isLoading = false
        }
    }

    LaunchedEffect(Unit) {
        dataStore.getAutoScanOnStartupEnabled().collect { enabled ->
            android.util.Log.d("SettingsScreen", "Загружено состояние автосканирования: $enabled")
            isAutoScanOnStartupEnabled = enabled
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Настройки") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Назад")
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(horizontal = 16.dp, vertical = 16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Карточка для фонового сканирования
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f))
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(
                        modifier = Modifier.weight(1f)
                    ) {
                        Text(
                            text = "Прием оплат в фоне",
                            style = MaterialTheme.typography.bodyLarge,
                            fontWeight = androidx.compose.ui.text.font.FontWeight.Medium
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "Сканирование BLE в фоне и push-уведомления",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    Switch(
                        checked = isBackgroundScanEnabled,
                        onCheckedChange = { enabled ->
                            android.util.Log.d("SettingsScreen", "Переключатель фонового сканирования нажат: $enabled")
                            if (enabled) {
                                // Сначала проверяем BLE-разрешения
                                if (!hasBlePermissions(context)) {
                                    android.util.Log.d("SettingsScreen", "Нет BLE-разрешений, показываем диалог")
                                    showBlePermissionDialog = true
                                    return@Switch
                                }
                                // Затем проверяем разрешение на фоновое местоположение
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                    if (ContextCompat.checkSelfPermission(
                                            context,
                                            Manifest.permission.ACCESS_BACKGROUND_LOCATION
                                        ) != PackageManager.PERMISSION_GRANTED
                                    ) {
                                        android.util.Log.d("SettingsScreen", "Нет разрешения на фоновое местоположение, показываем диалог")
                                        showPermissionDialog = true
                                        return@Switch
                                    }
                                }
                                android.util.Log.d("SettingsScreen", "Все разрешения есть, включаем фоновое сканирование")
                                isBackgroundScanEnabled = true
                                scope.launch {
                                    dataStore.setBackgroundScanEnabled(true)
                                    startBleScanService(context, isBackground = true)
                                    android.util.Log.d("SettingsScreen", "startBleScanService вызван (фон)")
                                }
                            } else {
                                android.util.Log.d("SettingsScreen", "Выключаем фоновое сканирование")
                                isBackgroundScanEnabled = false
                                scope.launch {
                                    dataStore.setBackgroundScanEnabled(false)
                                    stopBleScanService(context)
                                    android.util.Log.d("SettingsScreen", "stopBleScanService вызван")
                                }
                            }
                        },
                        enabled = !isLoading
                    )
                }
            }

            // Карточка для автосканирования при запуске
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f))
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(
                        modifier = Modifier.weight(1f)
                    ) {
                        Text(
                            text = "Сканирование при запуске",
                            style = MaterialTheme.typography.bodyLarge,
                            fontWeight = androidx.compose.ui.text.font.FontWeight.Medium
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "Автоматически начинать сканирование при открытии приложения",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    Switch(
                        checked = isAutoScanOnStartupEnabled,
                        onCheckedChange = { enabled ->
                            android.util.Log.d("SettingsScreen", "Переключатель автосканирования нажат: $enabled")
                            isAutoScanOnStartupEnabled = enabled
                            scope.launch {
                                dataStore.setAutoScanOnStartupEnabled(enabled)
                            }
                        },
                        enabled = true
                    )
                }
            }
        }
    }

    // Диалог запроса BLE-разрешений
    if (showBlePermissionDialog) {
        AlertDialog(
            onDismissRequest = { showBlePermissionDialog = false },
            title = { Text("Разрешения Bluetooth") },
            text = { Text("Для сканирования BLE-терминалов необходимы разрешения Bluetooth") },
            confirmButton = {
                TextButton(
                    onClick = {
                        android.util.Log.d("SettingsScreen", "Пользователь нажал Разрешить BLE")
                        showBlePermissionDialog = false
                        onRequestBlePermissions()
                    }
                ) {
                    Text("Разрешить")
                }
            },
            dismissButton = {
                TextButton(
                    onClick = {
                        android.util.Log.d("SettingsScreen", "Пользователь нажал Отмена BLE")
                        showBlePermissionDialog = false
                    }
                ) {
                    Text("Отмена")
                }
            }
        )
    }

    // Диалог запроса фонового разрешения
    if (showPermissionDialog) {
        AlertDialog(
            onDismissRequest = { showPermissionDialog = false },
            title = { Text("Разрешение на фоновую работу") },
            text = { Text("Для приема оплат в фоне необходимо разрешение на доступ к местоположению в фоновом режиме") },
            confirmButton = {
                TextButton(
                    onClick = {
                        android.util.Log.d("SettingsScreen", "Пользователь нажал Разрешить")
                        showPermissionDialog = false
                        onRequestBackgroundLocationPermission()
                    }
                ) {
                    Text("Разрешить")
                }
            },
            dismissButton = {
                TextButton(
                    onClick = {
                        android.util.Log.d("SettingsScreen", "Пользователь нажал Отмена")
                        showPermissionDialog = false
                    }
                ) {
                    Text("Отмена")
                }
            }
        )
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