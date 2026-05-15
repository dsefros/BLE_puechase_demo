import SwiftUI

struct AndroidParityBackground: View {
    var body: some View {
        Image("background")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
            .clipped()
            .allowsHitTesting(false)
    }
}

struct StaticFlowBackground: View {
    var body: some View {
        PaleWaveBackground()
            .overlay(HomePalette.overlay)
    }
}

struct PaleWaveBackground: View {
    var body: some View {
        ZStack {
            HomePalette.brandGray.opacity(0.40)

            Circle()
                .fill(HomePalette.brandOrange.opacity(0.08))
                .frame(width: 420,height: 420)
                .offset(x: -150,y: -260)

            Circle()
                .stroke(
                    HomePalette.brandOrange.opacity(0.10),
                    lineWidth: 34
                )
                .frame(width: 520,height: 520)
                .offset(x: 190,y: -290)

            RoundedRectangle(
                cornerRadius: 90,
                style: .continuous
            )
            .fill(HomePalette.brandOrange.opacity(0.06))
            .frame(width: 560,height: 180)
            .rotationEffect(.degrees(-17))
            .offset(x: -70,y: 250)
        }
    }
}
