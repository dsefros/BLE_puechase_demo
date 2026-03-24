package com.example.volnabledemo.data.ble

import java.math.BigInteger

class VolnaQrcIdConverter {
    private val alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    private val radix = BigInteger.valueOf(alphabet.length.toLong())

    fun fromBinary(payload: ByteArray): String {
        BleLog.d("BLE_Converter", "Converting QR ID, payload size: ${payload.size}")
        BleLog.d("BLE_Converter", "Payload hex: ${payload.joinToString("") { "%02x".format(it) }}")

        if (payload.isEmpty()) {
            BleLog.d("BLE_Converter", "Empty payload, returning empty string")
            return ""
        }

        if (payload.all { it.toInt() == 0 }) {
            BleLog.d("BLE_Converter", "All zeros, returning 0")
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
        BleLog.d("BLE_Converter", "Converted result: $result")
        return result
    }
}
