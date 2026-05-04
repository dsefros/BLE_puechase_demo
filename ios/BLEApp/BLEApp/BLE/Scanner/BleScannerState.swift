import Foundation

enum BleScannerState: String, Equatable {
    case idle
    case unauthorized
    case poweredOff
    case unsupported
    case resetting
    case ready
    case scanning
}
