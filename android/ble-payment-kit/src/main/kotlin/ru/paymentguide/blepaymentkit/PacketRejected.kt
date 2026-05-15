package ru.paymentguide.blepaymentkit

internal class PacketRejected(val reason: BlePacketRejectReason) : RuntimeException(reason.name)
