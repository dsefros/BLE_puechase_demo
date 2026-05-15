package ru.paymentguide.blepaymentkit

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import java.time.Instant

class BlePaymentKitTest {
    private val reference = Instant.parse("2026-05-15T11:00:00Z")
    private val config = BlePaymentConfig(
        supportedPacketVersion = 1,
        requiredCapabilityMask = 0x80,
        manufacturerId = 0xF001,
        rssiThreshold = -70,
    )

    @Test
    fun acceptedValidPacket() {
        val result = BlePaymentKit(config).process(validInput())
        val accepted = assertIs<BlePacketProcessingResult.Accepted>(result)
        assertEquals("74", accepted.candidate.qrcId)
        assertEquals("https://qr.nspk.ru/74", accepted.candidate.qrLink)
        assertEquals(12_345L, accepted.candidate.amountMinor)
        assertEquals("Demo Merchant", accepted.candidate.merchantName)
        assertEquals(-62, accepted.candidate.finalRssi)
        assertEquals(2, accepted.candidate.rssiDelta)
    }

    @Test fun noPrefixRuleMapsPlaceholderToUnsupportedVersion() = assertRejected(validInput(advertisementHex = "FF80010100"), BlePacketRejectReason.unsupportedVersion)
    @Test fun weakRssi() = assertRejected(validInput(rssi = -73), BlePacketRejectReason.signalBelowThreshold)
    @Test fun missingField() = assertRejected(validInput(scanResponseHex = null), BlePacketRejectReason.missingRequiredField)
    @Test fun malformedPacket() = assertRejected(validInput(scanResponseHex = "0001"), BlePacketRejectReason.malformedPayload)
    @Test fun unsupportedVersion() = assertRejected(validInput(advertisementHex = "4280010100"), BlePacketRejectReason.unsupportedVersion)

    @Test
    fun duplicatePlaceholderIsAcceptedBecauseCurrentAppHasNoDuplicatePolicy() {
        val sdk = BlePaymentKit(config)
        assertIs<BlePacketProcessingResult.Accepted>(sdk.process(validInput()))
        assertIs<BlePacketProcessingResult.Accepted>(sdk.process(validInput()))
    }

    @Test
    fun expiredPlaceholderIsAcceptedBecauseCurrentAppHasNoExpiryPolicy() {
        assertIs<BlePacketProcessingResult.Accepted>(BlePaymentKit(config).process(validInput(timestamp = Instant.parse("2026-05-15T10:58:30Z"))))
    }

    private fun assertRejected(input: BlePacketInput, reason: BlePacketRejectReason) {
        assertEquals(BlePacketProcessingResult.Rejected(reason), BlePaymentKit(config).process(input))
    }

    private fun validInput(
        advertisementHex: String = "2280010100",
        scanResponseHex: String? = "0000303944656D6F204D65726368616E74",
        rssi: Int = -60,
        timestamp: Instant = reference,
    ): BlePacketInput = BlePacketInput(
        advertisementData = ByteUtils.hexToBytes(advertisementHex),
        scanResponseData = scanResponseHex?.let(ByteUtils::hexToBytes),
        manufacturerId = 0xF001,
        rssi = rssi,
        timestamp = timestamp,
        deviceIdentifier = "peripheral-demo-001",
        localName = "Volna Demo Terminal",
    )
}
