package com.example.volnabledemo.data.ble

import android.util.Log

internal object BleLog {
    fun d(tag: String, message: String) {
        safeLog { Log.d(tag, message) }
    }

    fun e(tag: String, message: String) {
        safeLog { Log.e(tag, message) }
    }

    private inline fun safeLog(block: () -> Int) {
        try {
            block()
        } catch (_: RuntimeException) {
            // android.util.Log throws in plain JVM unit tests.
        } catch (_: NoClassDefFoundError) {
            // android.util.Log may be unavailable in non-Android runtime.
        }
    }
}
