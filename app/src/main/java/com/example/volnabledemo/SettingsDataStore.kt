package com.example.volnabledemo

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "volna_settings")

class SettingsDataStore(private val context: Context) {

    companion object {
        private val BACKGROUND_SCAN_ENABLED = booleanPreferencesKey("background_scan_enabled")
        private val AUTO_SCAN_ON_STARTUP_ENABLED = booleanPreferencesKey("auto_scan_on_startup_enabled")
    }

    fun getBackgroundScanEnabled(): Flow<Boolean> {
        return context.dataStore.data.map { preferences ->
            preferences[BACKGROUND_SCAN_ENABLED] ?: false
        }
    }

    suspend fun setBackgroundScanEnabled(enabled: Boolean) {
        context.dataStore.edit { preferences ->
            preferences[BACKGROUND_SCAN_ENABLED] = enabled
        }
    }

    fun getAutoScanOnStartupEnabled(): Flow<Boolean> {
        return context.dataStore.data.map { preferences ->
            preferences[AUTO_SCAN_ON_STARTUP_ENABLED] ?: false
        }
    }

    suspend fun setAutoScanOnStartupEnabled(enabled: Boolean) {
        context.dataStore.edit { preferences ->
            preferences[AUTO_SCAN_ON_STARTUP_ENABLED] = enabled
        }
    }
}