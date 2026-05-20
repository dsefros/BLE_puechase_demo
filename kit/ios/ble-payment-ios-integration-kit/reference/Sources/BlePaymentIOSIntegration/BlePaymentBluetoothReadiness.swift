import CoreBluetooth

public enum BlePaymentBluetoothReadiness {
    case ready
    case bluetoothUnavailable
    case unauthorized

    public static func from(state: CBManagerState, authorization: CBManagerAuthorization) -> BlePaymentBluetoothReadiness {
        guard authorization == .allowedAlways else { return .unauthorized }
        return state == .poweredOn ? .ready : .bluetoothUnavailable
    }
}
