import SwiftUI

struct ScanningStateView: View {
    let onCancel: () -> Void
    let isEnabled: Bool

    var body: some View {
        VStack(spacing: 0) {
            FixedTopBar()

            VStack(spacing: 0) {
                Text("Пожалуйста, подождите")
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(HomePalette.brandBlack)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .padding(.horizontal, 28)

                ScanningLoaderView()
                    .padding(.top, 16)

                Text("Сканирование...")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(HomePalette.brandBlack)
                    .multilineTextAlignment(.center)
                    .padding(.top, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

            BottomCTAContainer {
                BluePrimaryButton(title: "Отмена", action: onCancel, isEnabled: isEnabled)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FixedTopBar: View {
    var body: some View {
        Color.clear
            .frame(height: 60)
            .frame(maxWidth: .infinity)
    }
}

struct ScanningLoaderView: View {
    var body: some View {
        LottieView(
            animationName: "loader",
            loopMode: .loop,
            contentMode: .aspectFit,
            autoplay: true,
            fallback: { DotsLoaderFallback() }
        )
        .frame(width: 220, height: 220)
        .allowsHitTesting(false)
    }
}

struct DotsLoaderFallback: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { timeline in
            let elapsed = timeline.date.timeIntervalSinceReferenceDate
            let activeDot = Int((elapsed / 0.35).truncatingRemainder(dividingBy: 3))
            HStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(HomePalette.brandBlack.opacity(activeDot == index ? 1.0 : 0.30))
                        .frame(width: activeDot == index ? 14 : 11, height: activeDot == index ? 14 : 11)
                        .animation(.easeInOut(duration: 0.2), value: activeDot)
                }
            }
        }
        .padding(30)
    }
}
