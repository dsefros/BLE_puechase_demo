package com.example.volnabledemo.data.ble

import android.util.Log

class SignalStrengthValidator(private val threshold: Int) {
    fun finalRssi(rssi: Int, rssiDelta: Int): Int = rssi - rssiDelta

    fun isValid(rssi: Int, rssiDelta: Int): Boolean {
        val final = finalRssi(rssi, rssiDelta)
        val isValid = final >= threshold
        Log.d("BLE_Validator", "RSSI: $rssi, Delta: $rssiDelta, Final: $final, Threshold: $threshold, Valid: $isValid")
        return isValid
    }
}