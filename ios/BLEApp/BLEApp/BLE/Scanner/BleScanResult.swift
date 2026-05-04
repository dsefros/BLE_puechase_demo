import Foundation

enum BleScanResult: Equatable {
    case started
    case stopped
    case unavailable(BleScannerState)
}
