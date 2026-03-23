package com.example.volnabledemo.data.ble

class SignalStrengthValidator(private val threshold: Int) {
    fun finalRssi(rssi: Int, rssiDelta: Int): Int = rssi - rssiDelta
    fun isValid(rssi: Int, rssiDelta: Int): Boolean = finalRssi(rssi, rssiDelta) >= threshold
}
