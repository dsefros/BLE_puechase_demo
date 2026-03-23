package com.example.volnabledemo.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable

private val colors = darkColorScheme()

@Composable
fun VolnaBleDemoTheme(content: @Composable () -> Unit) {
    MaterialTheme(colorScheme = colors, content = content)
}
