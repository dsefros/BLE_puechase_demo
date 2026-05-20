package ru.paymentguide.blepaymentkit.integration

import android.os.Build

object BlePaymentPermissions {
    fun requiredScanPermissions(): List<String> = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        listOf(android.Manifest.permission.BLUETOOTH_SCAN)
    } else {
        listOf(android.Manifest.permission.ACCESS_FINE_LOCATION)
    }
}
