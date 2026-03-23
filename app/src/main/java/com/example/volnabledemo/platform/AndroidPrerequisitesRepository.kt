package com.example.volnabledemo.platform

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.os.Build
import androidx.core.content.ContextCompat
import com.example.volnabledemo.domain.repository.PrerequisitesRepository

class AndroidPrerequisitesRepository(private val context: Context) : PrerequisitesRepository {
    override fun isBleSupported(): Boolean = context.packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)

    override fun isBluetoothEnabled(): Boolean {
        val manager = context.getSystemService(BluetoothManager::class.java)
        return manager?.adapter?.isEnabled ?: BluetoothAdapter.getDefaultAdapter()?.isEnabled ?: false
    }

    override fun hasRequiredPermissions(): Boolean = requiredPermissions().all {
        ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED
    }

    override fun hasInternetConnection(): Boolean {
        val connectivityManager = context.getSystemService(ConnectivityManager::class.java)
        val network = connectivityManager?.activeNetwork ?: return false
        val capabilities = connectivityManager.getNetworkCapabilities(network) ?: return false
        return capabilities.hasCapability(android.net.NetworkCapabilities.NET_CAPABILITY_INTERNET)
    }

    companion object {
        fun requiredPermissions(sdkInt: Int = Build.VERSION.SDK_INT): List<String> = if (sdkInt >= Build.VERSION_CODES.S) {
            listOf(Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT)
        } else {
            listOf(Manifest.permission.ACCESS_FINE_LOCATION)
        }

        fun permissionDeniedMessage(sdkInt: Int = Build.VERSION.SDK_INT): String = if (sdkInt >= Build.VERSION_CODES.S) {
            "Для BLE-сканирования нужны разрешения Nearby devices / Bluetooth. Разрешите доступ и повторите попытку."
        } else {
            "Для BLE-сканирования нужно разрешение на геолокацию. Разрешите доступ и повторите попытку."
        }
    }
}
