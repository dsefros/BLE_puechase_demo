import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel

    #if DEBUG
    @State private var demoScenario: HomeDemoScenario = .live
    #endif

    private var presentation: HomeScreenPresentation {
        #if DEBUG
        if demoScenario != .live {
            return HomeScreenPresentation.demo(demoScenario)
        }
        #endif

        return HomeScreenPresentation.live(from: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HomeHeaderView()

                #if DEBUG
                DemoScenarioPicker(scenario: $demoScenario)
                #endif

                PaymentFlowCard(presentation: presentation, formatAmount: formatAmount, onConfirm: confirmPaymentIfLive, onCancel: cancelConfirmationIfLive)

                ScannerStatusCard(status: presentation.scannerStatus)

                if presentation.canShowScanButtons {
                    ScanActionButtons(
                        canStartScanAction: presentation.canStartScanAction,
                        canStopScanAction: presentation.canStopScanAction,
                        onStartScan: startScanIfLive,
                        onStopScan: stopScanIfLive,
                        isLiveMode: presentation.isLiveMode
                    )
                }

                DiagnosticsSection(presentation: presentation)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }



    private func confirmPaymentIfLive() {
        guard presentation.isLiveMode else { return }
        Task { await viewModel.confirmPayment() }
    }

    private func cancelConfirmationIfLive() {
        guard presentation.isLiveMode else { return }
        viewModel.cancelConfirmation()
    }

    private func startScanIfLive() {
        guard presentation.isLiveMode else { return }
        viewModel.startScan()
    }

    private func stopScanIfLive() {
        guard presentation.isLiveMode else { return }
        viewModel.stopScan()
    }

    func formatAmount(_ amountMinor: UInt32) -> String {
        let rubles = amountMinor / 100
        let kopecks = amountMinor % 100
        return "\(rubles) RUB \(String(format: "%02d", kopecks)) kop"
    }
}

private struct HomeHeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("BLE Payment")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Foreground payment discovery")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

private struct ScannerStatusCard: View {
    let status: BleScannerStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Scanner status", systemImage: "dot.radiowaves.left.and.right")
                .font(.headline)
            Text(status.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(status.isBlocking ? .red : .primary)
            Text(status.message)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .modifier(HomeCardStyle())
    }
}

private struct PaymentFlowCard: View {
    let presentation: HomeScreenPresentation
    let formatAmount: (UInt32) -> String
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Payment flow", systemImage: "creditcard")
                .font(.headline)

            switch presentation.flowState {
            case .idle:
                Text("Ready to start payment-terminal scan.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            case .scanning:
                Text("Searching for a payment terminal or tag nearby…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            case .readyForConfirmation(let candidate):
                CandidateConfirmationCard(candidate: candidate, formatAmount: formatAmount, onConfirm: onConfirm, onCancel: onCancel, isLiveMode: presentation.isLiveMode)
            case .submittingPayment(let candidate):
                CandidateSummary(candidate: candidate, formatAmount: formatAmount)
                ProgressView("Submitting payment…")
                    .padding(.top, 4)
            case .paymentSuccess(let candidate):
                PaymentSuccessCard(candidate: candidate, formatAmount: formatAmount, onScanAgain: onCancel, isLiveMode: presentation.isLiveMode)
            case .paymentError(let candidate, let message):
                PaymentErrorCard(candidate: candidate, message: message, formatAmount: formatAmount, onScanAgain: onCancel, isLiveMode: presentation.isLiveMode)
            case .scannerUnavailable(let message), .blockingError(let message):
                PaymentErrorCard(candidate: nil, message: message, formatAmount: formatAmount, onScanAgain: onCancel, isLiveMode: presentation.isLiveMode)
            }
        }
        .modifier(HomeCardStyle())
    }
}

private struct CandidateConfirmationCard: View {
    let candidate: PaymentCandidate
    let formatAmount: (UInt32) -> String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    let isLiveMode: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ready for confirmation")
                .font(.title3)
                .fontWeight(.semibold)
            CandidateSummary(candidate: candidate, formatAmount: formatAmount)
            HStack {
                Button("Confirm payment", action: onConfirm)
                    .buttonStyle(.borderedProminent)
                    .disabled(!isLiveMode)
                Button("Cancel / Scan again", action: onCancel)
                    .buttonStyle(.bordered)
                    .disabled(!isLiveMode)
            }
            if !isLiveMode {
                Text("Preview mode: confirmation actions are disabled.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct CandidateSummary: View {
    let candidate: PaymentCandidate
    let formatAmount: (UInt32) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(candidate.merchant)
                .font(.headline)
            Text(formatAmount(candidate.amountMinor))
                .font(.subheadline)
            Text("QRC ID: \(candidate.qrcID.isEmpty ? "(empty)" : candidate.qrcID)")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text("RSSI \(candidate.rssi), final \(candidate.finalRSSI), Δ\(candidate.rssiDelta)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct PaymentSuccessCard: View {
    let candidate: PaymentCandidate
    let formatAmount: (UInt32) -> String
    let onScanAgain: () -> Void
    let isLiveMode: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Payment confirmed", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.headline)
            CandidateSummary(candidate: candidate, formatAmount: formatAmount)
            Button("Scan again", action: onScanAgain)
                .buttonStyle(.borderedProminent)
                .disabled(!isLiveMode)
        }
    }
}

private struct PaymentErrorCard: View {
    let candidate: PaymentCandidate?
    let message: String
    let formatAmount: (UInt32) -> String
    let onScanAgain: () -> Void
    let isLiveMode: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Payment error", systemImage: "xmark.octagon.fill")
                .foregroundStyle(.red)
                .font(.headline)
            Text(message)
                .font(.subheadline)
            if let candidate {
                CandidateSummary(candidate: candidate, formatAmount: formatAmount)
            }
            Button("Scan again", action: onScanAgain)
                .buttonStyle(.bordered)
                .disabled(!isLiveMode)
        }
    }
}

private struct ScanActionButtons: View {
    let canStartScanAction: Bool
    let canStopScanAction: Bool
    let onStartScan: () -> Void
    let onStopScan: () -> Void
    let isLiveMode: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button("Start scan", action: onStartScan)
                    .buttonStyle(.borderedProminent)
                    .disabled(!canStartScanAction || !isLiveMode)

                Button("Stop scan", action: onStopScan)
                    .buttonStyle(.bordered)
                    .disabled(!canStopScanAction || !isLiveMode)
            }
            if !isLiveMode {
                Text("Preview mode: scan actions are disabled.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .modifier(HomeCardStyle())
    }
}

private struct DiagnosticsSection: View {
    let presentation: HomeScreenPresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Diagnostics", systemImage: "wrench.and.screwdriver")
                .font(.headline)
            Text("Raw scanner state: \(presentation.scannerState.rawValue)")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let rejection = presentation.latestParseRejection {
                Text("Latest parse rejection: \(rejection)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if presentation.diagnostics.isEmpty {
                Text("No advertisements captured yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(presentation.diagnostics) { advertisement in
                    DiagnosticAdvertisementRow(advertisement: advertisement)
                }
            }
        }
        .modifier(HomeCardStyle())
    }
}

private struct DiagnosticAdvertisementRow: View {
    let advertisement: BleDiscoveredAdvertisement

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(advertisement.peripheralName ?? "(no peripheral name)")
                .font(.subheadline)
                .fontWeight(.medium)
            Text("ID: \(advertisement.peripheralID.uuidString)")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("RSSI: \(advertisement.rssi)")
                .font(.caption)
            Text("Volna service data: \(advertisement.hasVolnaServiceData ? "present" : "missing")")
                .font(.caption2)
            Text("Manufacturer data: \(advertisement.hasManufacturerData ? "present" : "missing")")
                .font(.caption2)
        }
        .padding(8)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct HomeCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct HomeScreenPresentation {
    let scannerStatus: BleScannerStatus
    let flowState: PaymentFlowState
    let isScanning: Bool
    let scannerState: BleScannerState
    let diagnostics: [BleDiscoveredAdvertisement]
    let latestParseRejection: String?
    let canShowScanButtons: Bool
    let canStartScanAction: Bool
    let canStopScanAction: Bool
    let isLiveMode: Bool

    static func live(from viewModel: HomeViewModel) -> Self {
        Self(scannerStatus: viewModel.scannerStatus,
             flowState: viewModel.flowState,
             isScanning: viewModel.isScanning,
             scannerState: viewModel.scannerState,
             diagnostics: Array(viewModel.discoveredAdvertisements.prefix(5)),
             latestParseRejection: viewModel.latestParseRejection,
             canShowScanButtons: viewModel.canShowScanButtons,
             canStartScanAction: viewModel.canStartScanAction,
             canStopScanAction: viewModel.canStopScanAction,
             isLiveMode: true)
    }

    #if DEBUG
    static func demo(_ scenario: HomeDemoScenario) -> Self {
        let statusPresenter = BleScannerStatusPresenter()
        let sample = HomeDemoScenario.sampleCandidate
        switch scenario {
        case .live:
            return Self(scannerStatus: statusPresenter.status(for: .ready, isScanning: false), flowState: .idle, isScanning: false, scannerState: .ready, diagnostics: [], latestParseRejection: nil, canShowScanButtons: true, canStartScanAction: true, canStopScanAction: false, isLiveMode: true)
        case .unsupported:
            return Self(scannerStatus: statusPresenter.status(for: .unsupported, isScanning: false), flowState: .scannerUnavailable(message: "Bluetooth LE is unsupported on this device."), isScanning: false, scannerState: .unsupported, diagnostics: [HomeDemoScenario.sampleAdvertisement], latestParseRejection: "Missing Volna service/manufacturer data", canShowScanButtons: false, canStartScanAction: false, canStopScanAction: false, isLiveMode: false)
        case .ready:
            return Self(scannerStatus: statusPresenter.status(for: .ready, isScanning: false), flowState: .idle, isScanning: false, scannerState: .ready, diagnostics: [HomeDemoScenario.sampleAdvertisement], latestParseRejection: nil, canShowScanButtons: true, canStartScanAction: true, canStopScanAction: false, isLiveMode: false)
        case .scanning:
            return Self(scannerStatus: statusPresenter.status(for: .scanning, isScanning: true), flowState: .scanning, isScanning: true, scannerState: .scanning, diagnostics: [HomeDemoScenario.sampleAdvertisement], latestParseRejection: nil, canShowScanButtons: true, canStartScanAction: false, canStopScanAction: true, isLiveMode: false)
        case .candidate:
            return Self(scannerStatus: statusPresenter.status(for: .ready, isScanning: false), flowState: .readyForConfirmation(sample), isScanning: false, scannerState: .ready, diagnostics: [HomeDemoScenario.sampleAdvertisement], latestParseRejection: nil, canShowScanButtons: false, canStartScanAction: false, canStopScanAction: false, isLiveMode: false)
        case .submitting:
            return Self(scannerStatus: statusPresenter.status(for: .ready, isScanning: false), flowState: .submittingPayment(sample), isScanning: false, scannerState: .ready, diagnostics: [HomeDemoScenario.sampleAdvertisement], latestParseRejection: nil, canShowScanButtons: false, canStartScanAction: false, canStopScanAction: false, isLiveMode: false)
        case .success:
            return Self(scannerStatus: statusPresenter.status(for: .ready, isScanning: false), flowState: .paymentSuccess(sample), isScanning: false, scannerState: .ready, diagnostics: [HomeDemoScenario.sampleAdvertisement], latestParseRejection: nil, canShowScanButtons: false, canStartScanAction: false, canStopScanAction: false, isLiveMode: false)
        case .error:
            return Self(scannerStatus: statusPresenter.status(for: .ready, isScanning: false), flowState: .paymentError(sample, message: "Payment service unavailable"), isScanning: false, scannerState: .ready, diagnostics: [HomeDemoScenario.sampleAdvertisement], latestParseRejection: nil, canShowScanButtons: false, canStartScanAction: false, canStopScanAction: false, isLiveMode: false)
        }
    }
    #endif
}

#if DEBUG
enum HomeDemoScenario: String, CaseIterable, Identifiable {
    case live
    case unsupported
    case ready
    case scanning
    case candidate
    case submitting
    case success
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

private struct DemoScenarioPicker: View {
    @Binding var scenario: HomeDemoScenario

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Demo scenario (DEBUG)")
                .font(.headline)
            Picker("Scenario", selection: $scenario) {
                ForEach(HomeDemoScenario.allCases) { item in
                    Text(item.title).tag(item)
                }
            }
            .pickerStyle(.segmented)
            Text("Use Live to run the real scanner flow. All other scenarios are preview-only.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .modifier(HomeCardStyle())
    }
}
#endif
