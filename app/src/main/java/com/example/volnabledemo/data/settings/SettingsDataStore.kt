package com.example.volnabledemo.data.settings

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.preferencesDataStore
import com.example.volnabledemo.domain.repository.SettingsRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "app_settings")

class SettingsDataStore(private val context: Context) : SettingsRepository {
    private val autoScanKey = booleanPreferencesKey("auto_scan_enabled")

    override val isAutoScanEnabled: Flow<Boolean> = context.dataStore.data
        .map { preferences ->
            preferences[autoScanKey] ?: false
        }

    override suspend fun setAutoScanEnabled(enabled: Boolean) {
        context.dataStore.edit { preferences ->
            preferences[autoScanKey] = enabled
        }
    }
}
