import Foundation

#if DEBUG
enum HomeDemoScenario: String, CaseIterable, Identifiable {
    case live
    case unsupported
    case ready
    case scanning
    case candidate
    case submitting
    case success
    case timeoutError
    case error

    var id: String { rawValue }

    var title: String {
        switch self {
        case .live: return "Live"
        case .unsupported: return "Unsupported"
        case .ready: return "Ready"
        case .scanning: return "Scanning"
        case .candidate: return "Candidate"
        case .submitting: return "Submitting"
        case .success: return "Success"
        case .timeoutError: return "Timeout"
        case .error: return "Error"
        }
    }

    static var sampleCandidate: PaymentCandidate {
        PaymentCandidate(merchant: "Demo Merchant", amountMinor: 12345, qrcID: "DEMO123", rssi: -55, finalRSSI: -57, rssiDelta: 2, peripheralID: UUID(), peripheralName: "Demo BLE Terminal", timestamp: Date(timeIntervalSince1970: 1_700_000_000))
    }

    static var sampleAdvertisement: BleDiscoveredAdvertisement {
        BleDiscoveredAdvertisement(peripheralID: UUID(), peripheralName: "Demo BLE Terminal", rssi: -55, serviceUUIDs: [BleConfig.serviceUUIDString], volnaServiceData: Data([0x20, 0x80, 0x01, 0x01]), manufacturerData: Data([0x01, 0xF0, 0x00, 0x00]), timestamp: Date(timeIntervalSince1970: 1_700_000_100))
    }
}

#endif
