import Foundation

enum BleScanResult: Equatable {
    case notImplemented
    case candidates([BleDeviceCandidate])
}
