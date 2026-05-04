import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("BLE Purchase Demo")
                .font(.largeTitle)
                .bold()

            Text("MVP Scope: foreground-only, scan-only parity with Android.")

            Text("Scanner state: \(viewModel.scannerState.rawValue)")
            Text("Scanning active: \(viewModel.isScanning ? "Yes" : "No")")
                .font(.footnote)

            stateBlock

            if let rejection = viewModel.latestParseRejection {
                Text("Last parse rejection: \(rejection)")
                    .font(.footnote)
            }

            scanButtons

            List(viewModel.discoveredAdvertisements) { advertisement in
                VStack(alignment: .leading, spacing: 4) {
                    Text(advertisement.peripheralName ?? "(no peripheral name)")
                        .font(.headline)
                    Text("ID: \(advertisement.peripheralID.uuidString)")
                        .font(.caption)
                    Text("RSSI: \(advertisement.rssi)")
                        .font(.subheadline)
                    Text("Volna service data: \(advertisement.hasVolnaServiceData ? "present" : "missing")")
                        .font(.caption)
                    Text("Manufacturer data: \(advertisement.hasManufacturerData ? "present" : "missing")")
                        .font(.caption)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
    }

    @ViewBuilder
    var stateBlock: some View {
        switch viewModel.flowState {
        case .idle:
            Text("State: idle / ready to scan")
        case .scanning:
            Text("State: scanning")
        case .readyForConfirmation(let candidate):
            confirmationView(candidate: candidate)
        case .submittingPayment:
            Text("Submitting payment (placeholder)...")
        case .paymentSuccess(let candidate):
            VStack(alignment: .leading, spacing: 4) {
                Text("Payment confirmed (placeholder success).")
                    .bold()
                Text("Merchant: \(candidate.merchant)")
                Text("Amount: \(formatAmount(candidate.amountMinor))")
                Button("Scan again") { viewModel.cancelConfirmation() }
            }
        case .paymentError(_, let message):
            Text("Payment error: \(message)")
        case .scannerUnavailable(let message), .blockingError(let message):
            Text(message)
                .foregroundStyle(.red)
        }
    }

    var scanButtons: some View {
        HStack {
            Button("Start scan") {
                viewModel.startScan()
            }
            .buttonStyle(.borderedProminent)

            Button("Stop scan") {
                viewModel.stopScan()
            }
            .buttonStyle(.bordered)
        }
    }

    func confirmationView(candidate: PaymentCandidate) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ready for confirmation")
                .font(.headline)
            Text("Merchant: \(candidate.merchant)")
            Text("Amount: \(formatAmount(candidate.amountMinor))")
            Text("QRC ID: \(candidate.qrcID.isEmpty ? "(empty)" : candidate.qrcID)")
            Text("Diagnostics: RSSI=\(candidate.rssi), finalRSSI=\(candidate.finalRSSI), delta=\(candidate.rssiDelta)")
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack {
                Button("Confirm payment") {
                    viewModel.confirmPayment()
                }
                .buttonStyle(.borderedProminent)

                Button("Cancel / Scan again") {
                    viewModel.cancelConfirmation()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(8)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    func formatAmount(_ amountMinor: UInt32) -> String {
        let rubles = amountMinor / 100
        let kopecks = amountMinor % 100
        return "\(rubles) RUB \(String(format: "%02d", kopecks)) kop (minor: \(amountMinor))"
    }
}
