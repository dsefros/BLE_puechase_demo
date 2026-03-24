package com.example.volnabledemo

import com.example.volnabledemo.data.ble.AdvertisementPacketParser
import com.example.volnabledemo.data.ble.QrLinkBuilder
import com.example.volnabledemo.data.ble.ScanResponseParser
import com.example.volnabledemo.data.ble.SignalStrengthValidator
import com.example.volnabledemo.data.ble.VolnaCandidateAssembler
import com.example.volnabledemo.data.ble.VolnaQrcIdConverter
import com.example.volnabledemo.domain.model.VolnaContract
import com.google.common.truth.Truth.assertThat
import org.junit.Test
import java.math.BigInteger

class VolnaLogicTest {
    private val qrcIdConverter = VolnaQrcIdConverter()
    private val base62Alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

    @Test
    fun `parses first byte with packet version 1 and positive rssi delta`() {
        val parser = AdvertisementPacketParser(qrcIdConverter)
        val serviceData = byteArrayOf(
            0x22,
            0x80.toByte(),
            0x10,
        ) + qrcIdBinary("ABC")

        val packet = parser.parse(serviceData).getOrThrow()

        assertThat(packet.packetVersion).isEqualTo(1)
        assertThat(packet.rssiDelta).isEqualTo(2)
    }

    @Test
    fun `parses signed 5-bit negative rssi delta`() {
        val parser = AdvertisementPacketParser(qrcIdConverter)
        val serviceData = byteArrayOf(
            0x3F,
            0x80.toByte(),
            0x01,
        ) + qrcIdBinary("Z")

        val packet = parser.parse(serviceData).getOrThrow()

        assertThat(packet.packetVersion).isEqualTo(1)
        assertThat(packet.rssiDelta).isEqualTo(-1)
    }

    @Test
    fun `rejects unsupported packet version`() {
        val parser = AdvertisementPacketParser(qrcIdConverter)
        val serviceData = byteArrayOf(
            0x42,
            0x80.toByte(),
            0x01,
        ) + qrcIdBinary("123")

        val result = parser.parse(serviceData)

        assertThat(result.isFailure).isTrue()
    }

    @Test
    fun `accepts only top capability bit for c2b online`() {
        val parser = AdvertisementPacketParser(qrcIdConverter)
        val validServiceData = byteArrayOf(
            0x22,
            0x80.toByte(),
            0x01,
        ) + qrcIdBinary("124")
        val invalidServiceData = byteArrayOf(
            0x22,
            0x01,
            0x01,
        ) + qrcIdBinary("125")

        assertThat(parser.parse(validServiceData).isSuccess).isTrue()
        assertThat(parser.parse(invalidServiceData).isFailure).isTrue()
    }

    @Test
    fun `parses big endian amount and cp1251 merchant`() {
        val parser = ScanResponseParser()
        val payload = byteArrayOf(0x00, 0x00, 0x30, 0x39) + "Тест".toByteArray(charset("windows-1251"))

        val response = parser.parse(0xF001, payload).getOrThrow()

        assertThat(response.amountMinor).isEqualTo(12345)
        assertThat(response.merchantName).isEqualTo("Тест")
    }

    @Test
    fun `builds qr link`() {
        assertThat(QrLinkBuilder("https://qr.nspk.ru/").build("ABC123")).isEqualTo("https://qr.nspk.ru/ABC123")
    }

    @Test
    fun `converts qrc id from binary without forced fixed-width padding`() {
        val converted = qrcIdConverter.fromBinary(qrcIdBinary("ABC"))

        assertThat(converted).isEqualTo("ABC")
    }

    @Test
    fun `preserves mixed case qrc id when converting from binary`() {
        val expectedQrcId = "KDtpuFqqhiJfXyFQqjGzMtIG4NOPIgsd"
        val converted = qrcIdConverter.fromBinary(qrcIdBinary(expectedQrcId))

        assertThat(converted).isEqualTo(expectedQrcId)
        assertThat(converted).isNotEqualTo(expectedQrcId.uppercase())
    }

    @Test
    fun `converts all-zero qrc id payload to zero digit`() {
        val converted = qrcIdConverter.fromBinary(ByteArray(VolnaContract.qrcIdBytesLength))

        assertThat(converted).isEqualTo("0")
    }

    @Test
    fun `validates signal using signed rssi delta`() {
        val validator = SignalStrengthValidator(-70)

        assertThat(validator.finalRssi(-62, 2)).isEqualTo(-64)
        assertThat(validator.finalRssi(-62, -3)).isEqualTo(-59)
        assertThat(validator.isValid(-62, 2)).isTrue()
        assertThat(validator.isValid(-68, 3)).isFalse()
    }

    @Test
    fun `assembles candidate when all checks pass`() {
        val adv = AdvertisementPacketParser(qrcIdConverter).parse(
            byteArrayOf(0x22, 0x80.toByte(), 0x01) + qrcIdBinary("ABD")
        ).getOrThrow()
        val resp = ScanResponseParser().parse(
            0xF001,
            byteArrayOf(0x00, 0x00, 0x00, 0x64) + "Магазин".toByteArray(charset("windows-1251"))
        ).getOrThrow()
        val assembler = VolnaCandidateAssembler(SignalStrengthValidator(-80), QrLinkBuilder("https://qr.nspk.ru/"))

        val candidate = assembler.assemble(adv, resp, -60).getOrThrow()

        assertThat(candidate.amountMinor).isEqualTo(100)
        assertThat(candidate.merchantName).isEqualTo("Магазин")
        assertThat(candidate.qrLink).isEqualTo("https://qr.nspk.ru/" + candidate.qrcId)
        assertThat(candidate.rssiFinal).isEqualTo(-62)
    }

    @Test
    fun `qr link contains exact mixed case qrc id`() {
        val expectedQrcId = "KDtpuFqqhiJfXyFQqjGzMtIG4NOPIgsd"
        val advertisementPacket = AdvertisementPacketParser(qrcIdConverter).parse(
            byteArrayOf(0x22, 0x80.toByte(), 0x01) + qrcIdBinary(expectedQrcId)
        ).getOrThrow()
        val response = ScanResponseParser().parse(
            0xF001,
            byteArrayOf(0x00, 0x00, 0x00, 0x64) + "Магазин".toByteArray(charset("windows-1251"))
        ).getOrThrow()
        val assembler = VolnaCandidateAssembler(SignalStrengthValidator(-80), QrLinkBuilder("https://qr.nspk.ru/"))

        val candidate = assembler.assemble(advertisementPacket, response, -60).getOrThrow()

        assertThat(candidate.qrcId).isEqualTo(expectedQrcId)
        assertThat(candidate.qrLink).isEqualTo("https://qr.nspk.ru/$expectedQrcId")
    }

    private fun qrcIdBinary(qrcId: String): ByteArray {
        val value = qrcId.fold(BigInteger.ZERO) { acc, char ->
            val digit = base62Alphabet.indexOf(char)
            require(digit >= 0) { "Unsupported QRC ID character: $char" }
            acc * BigInteger.valueOf(base62Alphabet.length.toLong()) + BigInteger.valueOf(digit.toLong())
        }
        val bytes = value.toByteArray().let { if (it.firstOrNull() == 0.toByte()) it.copyOfRange(1, it.size) else it }
        require(bytes.size <= VolnaContract.qrcIdBytesLength)
        return ByteArray(VolnaContract.qrcIdBytesLength - bytes.size) + bytes
    }
}
