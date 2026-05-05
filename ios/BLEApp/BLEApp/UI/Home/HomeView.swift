import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerView
                scannerStatusView
                stateBlock
                if viewModel.canShowScanButtons {
                    scanButtons
                }
                diagnosticsView
            }
            .padding()
        }
    }

    var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("BLE Payment")
                .font(.largeTitle)
                .bold()
            Text("Foreground BLE payment discovery")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    var scannerStatusView: some View {
        let status = viewModel.scannerStatus
        return VStack(alignment: .leading, spacing: 4) {
            Text(status.title)
                .font(.headline)
                .foregroundStyle(status.isBlocking ? .red : .primary)
            Text(status.message)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    var stateBlock: some View {
        switch viewModel.flowState {
        case .idle:
            Text("Ready to start payment-terminal scan.")
        case .scanning:
            Text("Searching for a payment terminal or tag nearby…")
        case .readyForConfirmation(let candidate):
            confirmationView(candidate: candidate)
        case .submittingPayment:
            Text("Submitting payment (placeholder)…")
        case .paymentSuccess(let candidate):
            successView(candidate: candidate)
        case .paymentError(let candidate, let message):
            errorView(candidate: candidate, message: message)
        case .scannerUnavailable(let message), .blockingError(let message):
            errorView(candidate: nil, message: message)
        }
    }

    var scanButtons: some View {
        HStack {
            Button("Start scan") { viewModel.startScan() }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canStartScanAction)

            Button("Stop scan") { viewModel.stopScan() }
                .buttonStyle(.bordered)
                .disabled(!viewModel.canStopScanAction)
        }
    }

    func confirmationView(candidate: PaymentCandidate) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ready for confirmation")
                .font(.headline)
            Text("Merchant: \(candidate.merchant)")
            Text("Amount: \(formatAmount(candidate.amountMinor))")
            Text("QRC ID: \(candidate.qrcID.isEmpty ? "(empty)" : candidate.qrcID)")
            Text("RSSI: \(candidate.rssi), finalRSSI: \(candidate.finalRSSI), rssiDelta: \(candidate.rssiDelta)")
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack {
                Button("Confirm payment") {
                    Task { await viewModel.confirmPayment() }
                }
                .buttonStyle(.borderedProminent)

                Button("Cancel / Scan again") { viewModel.cancelConfirmation() }
                    .buttonStyle(.bordered)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    func successView(candidate: PaymentCandidate) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Payment confirmed")
                .font(.headline)
            Text("Merchant: \(candidate.merchant)")
            Text("Amount: \(formatAmount(candidate.amountMinor))")
            Text("QRC ID: \(candidate.qrcID)")
            Button("Scan again") { viewModel.cancelConfirmation() }
                .buttonStyle(.borderedProminent)
        }
    }

    func errorView(candidate: PaymentCandidate?, message: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Payment error")
                .font(.headline)
                .foregroundStyle(.red)
            Text(message)
            if let candidate {
                Text("Merchant: \(candidate.merchant)")
                Text("Amount: \(formatAmount(candidate.amountMinor))")
            }
            Button("Scan again") { viewModel.cancelConfirmation() }
                .buttonStyle(.bordered)
        }
    }

    var diagnosticsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Diagnostics")
                .font(.headline)

            Text("Raw scanner state: \(viewModel.scannerState.rawValue)")
                .font(.footnote)
                .foregroundStyle(.secondary)

            if let rejection = viewModel.latestParseRejection {
                Text("Latest parse rejection: \(rejection)")
                    .font(.footnote)
            }

            ForEach(viewModel.discoveredAdvertisements) { advertisement in
                VStack(alignment: .leading, spacing: 2) {
                    Text(advertisement.peripheralName ?? "(no peripheral name)")
                        .font(.subheadline)
                    Text("ID: \(advertisement.peripheralID.uuidString)")
                        .font(.caption2)
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
    }

    func formatAmount(_ amountMinor: UInt32) -> String {
        let rubles = amountMinor / 100
        let kopecks = amountMinor % 100
        return "\(rubles) RUB \(String(format: "%02d", kopecks)) kop (minor: \(amountMinor))"
    }
}
