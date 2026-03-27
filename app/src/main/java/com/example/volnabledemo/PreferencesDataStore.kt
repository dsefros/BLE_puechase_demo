package com.example.volnabledemo

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

// Расширение для Context
val Context.settingsDataStore: DataStore<Preferences> by preferencesDataStore(name = "settings")

// Ключи для настроек
val BACKGROUND_SCAN_ENABLED = booleanPreferencesKey("background_scan_enabled")

// Функции для работы с DataStore
suspend fun DataStore<Preferences>.setBackgroundScanEnabled(enabled: Boolean) {
    edit { preferences ->
        preferences[BACKGROUND_SCAN_ENABLED] = enabled
    }
}

fun DataStore<Preferences>.getBackgroundScanEnabled(): Flow<Boolean> {
    return data.map { preferences ->
        preferences[BACKGROUND_SCAN_ENABLED] ?: false
    }
}