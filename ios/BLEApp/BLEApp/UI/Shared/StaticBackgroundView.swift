import SwiftUI

struct StaticBackgroundView: View {
    var body: some View {
        Image("background")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }
}
