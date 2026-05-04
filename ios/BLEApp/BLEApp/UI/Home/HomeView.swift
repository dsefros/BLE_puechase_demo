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


            if let candidate = viewModel.latestValidCandidate {
                Text("Latest candidate: \(candidate.merchant), \(candidate.amountMinor), QRC: \(candidate.qrcID)")
                    .font(.footnote)
            } else if let rejection = viewModel.latestParseRejection {
                Text("Last parse rejection: \(rejection)")
                    .font(.footnote)
            }

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
}
