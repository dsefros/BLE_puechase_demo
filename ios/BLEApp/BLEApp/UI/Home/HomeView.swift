import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("BLE Purchase Demo")
                .font(.largeTitle)
                .bold()

            Text("MVP Scope: foreground-only, scan-only parity with Android.")
            Text("BLE scanning is not implemented in this PR. This is a project skeleton.")
                .foregroundStyle(.secondary)

            Button("Start scan (placeholder)") {
                viewModel.startScanPlaceholder()
            }
            .buttonStyle(.borderedProminent)

            Text("State: \(viewModel.flowState.rawValue)")
                .font(.footnote)
        }
        .padding()
    }
}
