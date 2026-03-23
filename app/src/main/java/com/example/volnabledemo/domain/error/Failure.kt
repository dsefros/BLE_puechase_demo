package com.example.volnabledemo.domain.error

sealed interface Failure {
    sealed interface PrerequisiteFailure : Failure {
        data object BleUnsupported : PrerequisiteFailure
        data object BluetoothDisabled : PrerequisiteFailure
        data object PermissionsDenied : PrerequisiteFailure
        data object NoInternet : PrerequisiteFailure
    }

    sealed interface ScanFailure : Failure {
        data object Timeout : ScanFailure
        data object HardwareError : ScanFailure
        data object InvalidPacket : ScanFailure
    }

    sealed interface PaymentFailure : Failure {
        data object Network : PaymentFailure
        data object HostRejected : PaymentFailure
        data object Serialization : PaymentFailure
        data object Unknown : PaymentFailure
    }
}
