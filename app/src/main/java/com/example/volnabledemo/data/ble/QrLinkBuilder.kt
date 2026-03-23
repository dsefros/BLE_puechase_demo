package com.example.volnabledemo.data.ble

class QrLinkBuilder(private val prefix: String) {
    fun build(qrcId: String): String = prefix.trimEnd('/') + "/" + qrcId
}
