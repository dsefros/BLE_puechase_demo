package com.example.volnabledemo.data.ble

import android.util.Log
import java.math.BigInteger

class VolnaQrcIdConverter {
    private val radix = BigInteger.valueOf(36)
    private val alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"

    fun fromBinary(payload: ByteArray): String {
        Log.d("BLE_Converter", "Converting QR ID, payload size: ${payload.size}")
        Log.d("BLE_Converter", "Payload hex: ${payload.joinToString("") { "%02x".format(it) }}")

        if (payload.isEmpty()) {
            Log.d("BLE_Converter", "Empty payload, returning empty string")
            return ""
        }

        if (payload.all { it.toInt() == 0 }) {
            Log.d("BLE_Converter", "All zeros, returning 0")
            return "0"
        }

        var value = BigInteger(1, payload)
        val digits = StringBuilder()
        while (value > BigInteger.ZERO) {
            val divRem = value.divideAndRemainder(radix)
            digits.append(alphabet[divRem[1].toInt()])
            value = divRem[0]
        }

        val result = digits.reverse().toString()
        Log.d("BLE_Converter", "Converted result: $result")
        return result
    }
}