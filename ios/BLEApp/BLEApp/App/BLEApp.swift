import SwiftUI

@main
struct BLEApp: App {
    private let container = AppContainer()

    var body: some Scene {
        WindowGroup {
            HomeView(viewModel: HomeViewModel(container: container))
        }
    }
}
