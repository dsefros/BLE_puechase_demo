package com.example.volnabledemo.data.ble

import com.example.volnabledemo.domain.model.ScanResponseData
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.charset.Charset

class ScanResponseParser(
    private val cp1251: Charset = Charset.forName("windows-1251"),
) {
    fun parse(manufacturerId: Int, payload: ByteArray): Result<ScanResponseData> = runCatching {
        require(manufacturerId == 0xF001) { "Unsupported manufacturer" }
        require(payload.size >= 4) { "Manufacturer payload too short" }
        val amountMinor = ByteBuffer.wrap(payload.copyOfRange(0, 4)).order(ByteOrder.BIG_ENDIAN).int.toLong() and 0xFFFFFFFFL
        require(amountMinor > 0) { "Amount must be positive" }
        val merchantBytes = payload.copyOfRange(4, payload.size)
        val merchantName = merchantBytes.toString(cp1251).trimEnd('\u0000').trim()
        ScanResponseData(amountMinor = amountMinor, merchantName = merchantName.ifBlank { "Терминал Волна" })
    }
}
