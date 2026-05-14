import SwiftUI

struct PaymentErrorView: View {
    let candidate: PaymentCandidate
    let message: String
    let formatAmount: (UInt32) -> String
    let onClose: () -> Void
    let onRetry: () -> Void
    let isEnabled: Bool

    var body: some View {
        AndroidErrorView(
            title: "Ошибка оплаты",
            message: message,
            onClose: onClose,
            onRetry: onRetry,
            isEnabled: isEnabled
        )
        .accessibilityHint("Платеж для \(candidate.merchant), сумма \(formatAmount(candidate.amountMinor))")
    }
}

struct ScannerUnavailableView: View {
    let message: String
    let onClose: () -> Void
    let onRetry: () -> Void
    let isEnabled: Bool

    var body: some View {
        AndroidErrorView(title: "Ошибка", message: message, onClose: onClose, onRetry: onRetry, isEnabled: isEnabled)
    }
}

struct BlockingErrorView: View {
    let message: String
    let onClose: () -> Void
    let onRetry: () -> Void
    let isEnabled: Bool

    var body: some View {
        AndroidErrorView(title: "Ошибка", message: message, onClose: onClose, onRetry: onRetry, isEnabled: isEnabled)
    }
}

struct AndroidErrorView: View {
    let title: String
    let message: String
    let onClose: () -> Void
    let onRetry: () -> Void
    let isEnabled: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(HomePalette.brandDarkGray)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!isEnabled)
                .accessibilityLabel("На главный экран")
            }
            .frame(height: 60)
            .padding(.horizontal, 16)

            ErrorContent(title: title, message: message)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(.horizontal, 28)

            BottomCTAContainer {
                BluePrimaryButton(title: "Повторить", action: onRetry, isEnabled: isEnabled)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ErrorContent: View {
    let title: String
    let message: String

    var body: some View {
        ViewThatFits(in: .vertical) {
            content(iconSize: 220, verticalSpacing: 32)
            content(iconSize: 160, verticalSpacing: 18)
        }
    }

    private func content(iconSize: CGFloat, verticalSpacing: CGFloat) -> some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(HomePalette.brandRed)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity)

            Spacer().frame(height: verticalSpacing)

            LottieView(
                animationName: "failed",
                loopMode: .playOnce,
                contentMode: .aspectFit,
                autoplay: true,
                fallback: {
                    Circle()
                        .stroke(HomePalette.brandRed, lineWidth: 12)
                        .overlay(Text("!").font(.system(size: 76, weight: .bold)).foregroundStyle(HomePalette.brandRed))
                }
            )
            .frame(width: iconSize, height: iconSize)
            .allowsHitTesting(false)

            Spacer().frame(height: verticalSpacing)

            Text(message)
                .font(.system(size: 14, weight: .regular))
                .lineSpacing(10)
                .foregroundStyle(HomePalette.brandBlack)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity)
        }
    }
}
