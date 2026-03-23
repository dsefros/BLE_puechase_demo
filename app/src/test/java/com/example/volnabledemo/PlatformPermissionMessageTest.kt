package com.example.volnabledemo

import com.example.volnabledemo.platform.AndroidPrerequisitesRepository
import com.google.common.truth.Truth.assertThat
import org.junit.Test

class PlatformPermissionMessageTest {
    @Test
    fun `android 12 plus permission message mentions nearby devices`() {
        val message = AndroidPrerequisitesRepository.permissionDeniedMessage(31)

        assertThat(message).contains("Nearby devices")
        assertThat(message).contains("Bluetooth")
    }

    @Test
    fun `android 11 and below permission message mentions location`() {
        val message = AndroidPrerequisitesRepository.permissionDeniedMessage(30)

        assertThat(message).contains("геолокацию")
    }
}
