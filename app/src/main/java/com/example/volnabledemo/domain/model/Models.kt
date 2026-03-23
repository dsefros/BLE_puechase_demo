package com.example.volnabledemo.domain.model

import java.util.UUID

object VolnaContract {
    val serviceUuid: UUID = UUID.fromString("0000534B-0000-1000-8000-00805F9B34FB")
    const val manufacturerId: Int = 0xF001
    const val supportedPacketVersion: Int = 0b001
    const val requiredOnlineC2bCapabilityMask: Int = 0x80
    const val qrcIdBytesLength: Int = 21
}

data class AdvertisementPacket(
    val packetVersion: Int,
    val rssiDelta: Int,
    val terminalCapabilities: Int,
    val operationCounter: Int,
    val qrcId: String,
)

data class ScanResponseData(
    val amountMinor: Long,
    val merchantName: String,
)

data class VolnaCandidate(
    val qrcId: String,
    val qrLink: String,
    val amountMinor: Long,
    val merchantName: String,
    val rssi: Int,
    val rssiFinal: Int,
)

enum class ScanFailureReason {
    BleUnsupported,
    BluetoothDisabled,
    PermissionsDenied,
    NoInternet,
    TerminalNotFound,
    InvalidPacket,
}

enum class PaymentFailureReason {
    HostTimeout,
    HostError,
    InvalidPayload,
}

sealed interface PaymentFlowState {
    data object Idle : PaymentFlowState
    data object CheckingPrerequisites : PaymentFlowState
    data object Scanning : PaymentFlowState
    data class ReadyForConfirmation(val candidate: VolnaCandidate) : PaymentFlowState
    data class PaymentSuccess(val candidate: VolnaCandidate) : PaymentFlowState
    data class PaymentError(val message: String) : PaymentFlowState
    data class BlockingError(val message: String) : PaymentFlowState
    data class SubmittingPayment(val candidate: VolnaCandidate) : PaymentFlowState
}
