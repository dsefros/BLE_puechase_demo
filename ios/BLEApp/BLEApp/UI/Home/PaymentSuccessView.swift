import SwiftUI

struct PaymentSuccessView: View {
    let candidate: PaymentCandidate
    let formatAmount: (UInt32) -> String
    let onDone: () -> Void
    let isEnabled: Bool

    @State private var progress: CGFloat = 0
    @State private var isExiting = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            Text("Одобрено")
                .font(.system(size: 24, weight: .black))
                .lineSpacing(8)
                .foregroundStyle(HomePalette.brandGreen)
                .multilineTextAlignment(.center)

            Spacer().frame(height: 128)

            LottieView(
                animationName: "success",
                loopMode: .playOnce,
                contentMode: .aspectFit,
                autoplay: true,
                fallback: {
                    Circle()
                        .stroke(HomePalette.brandGreen, lineWidth: 12)
                        .overlay(Text("✓").font(.system(size: 76, weight: .bold)).foregroundStyle(HomePalette.brandGreen))
                }
            )
            .frame(width: 150, height: 150)

            Spacer().frame(height: 64)

            Text("Оплата")
                .font(.system(size: 16, weight: .regular))
                .tracking(0.8)
                .foregroundStyle(HomePalette.brandDarkGray)

            Text(formatAmount(candidate.amountMinor))
                .font(.system(size: 24, weight: .black))
                .lineSpacing(8)
                .foregroundStyle(HomePalette.brandBlack)
                .padding(.top, 8)

            GeometryReader { proxy in
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(HomePalette.brandGreen)
                    .frame(width: proxy.size.width * 0.6, height: 4)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 4)
            .padding(.top, 24)

            Text("Возврат на главный экран...")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(HomePalette.brandDarkGray)
                .padding(.top, 8)

            Spacer(minLength: 18)
        }
        .padding(.horizontal, 28)
        .opacity(isExiting ? 0 : 1)
        .scaleEffect(isExiting ? 0.001 : 1)
        .animation(.easeInOut(duration: 0.50), value: isExiting)
        .onAppear {
            progress = 0
            withAnimation(.linear(duration: 5)) { progress = 1 }
        }
        .task {
            try? await Task.sleep(nanoseconds: 4_500_000_000)
            guard !Task.isCancelled, isEnabled else { return }
            isExiting = true
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            onDone()
        }
    }
}
