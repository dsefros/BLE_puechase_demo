package com.example.volnabledemo.data.ble

import com.example.volnabledemo.domain.model.VolnaContract
import java.math.BigInteger

class VolnaQrcIdConverter {
    private val radix = BigInteger.valueOf(36)
    private val alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"

    fun fromBinary(payload: ByteArray): String {
        require(payload.size == VolnaContract.qrcIdBytesLength) {
            "QRC ID must be exactly ${VolnaContract.qrcIdBytesLength} bytes"
        }
        if (payload.all { it.toInt() == 0 }) {
            return "0"
        }

        var value = BigInteger(1, payload)
        val digits = StringBuilder()
        while (value > BigInteger.ZERO) {
            val divRem = value.divideAndRemainder(radix)
            digits.append(alphabet[divRem[1].toInt()])
            value = divRem[0]
        }

        return digits.reverse().toString()
    }
}
