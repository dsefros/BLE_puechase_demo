package ru.paymentguide.blepaymentkit

import java.math.BigInteger

internal object ByteUtils {
    fun unsignedBigEndianUInt32(bytes: ByteArray): Long? {
        if (bytes.size < 4) return null
        return bytes.take(4).fold(0L) { acc, byte -> (acc shl 8) or (byte.toLong() and 0xFF) }
    }

    fun base36UnsignedBigEndian(bytes: ByteArray): String {
        if (bytes.isEmpty()) return ""
        if (bytes.all { it.toInt() == 0 }) return "0"
        return BigInteger(1, bytes).toString(36).uppercase()
    }

    fun hexToBytes(hex: String): ByteArray {
        val clean = hex.filterNot { it.isWhitespace() }
        require(clean.length % 2 == 0) { "Hex string must have even length" }
        return clean.chunked(2).map { it.toInt(16).toByte() }.toByteArray()
    }
}
