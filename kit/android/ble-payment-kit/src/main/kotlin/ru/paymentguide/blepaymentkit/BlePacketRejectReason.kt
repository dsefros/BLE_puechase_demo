package ru.paymentguide.blepaymentkit

enum class BlePacketRejectReason {
    invalidPrefix,
    malformedPayload,
    missingRequiredField,
    weakRSSI,
    expiredPacket,
    unsupportedVersion,
    duplicatePacket,
    signalBelowThreshold,
    packetTooShort,
    invalidQrcId,
    unknown,
}
