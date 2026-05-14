import SwiftUI

struct BluetoothHeroIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(HomePalette.brandOrange.opacity(0.18))
                .frame(width: 170, height: 170)
                .blur(radius: 2)
            Circle()
                .fill(HomePalette.white)
                .frame(width: 132, height: 132)
                .shadow(color: HomePalette.brandOrange.opacity(0.20), radius: 18, x: 0, y: 8)
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 58, weight: .semibold))
                .foregroundStyle(HomePalette.brandOrange)
        }
    }
}

struct BluetoothHeroScanButton: View {
    let action: () -> Void

    private let containerSize: CGFloat = 320
    private let tapSize: CGFloat = 120

    var body: some View {
        ZStack {
            LottieView(
                animationName: "bluetooth",
                loopMode: .loop,
                contentMode: .aspectFit,
                autoplay: true,
                fallback: { BluetoothHeroIcon() }
            )
            .frame(width: containerSize, height: containerSize)
            .scaleEffect(0.25)
            .allowsHitTesting(false)

            Button(action: action) {
                Circle()
                    .fill(Color.clear)
                    .frame(width: tapSize, height: tapSize)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .frame(width: tapSize, height: tapSize)
            .contentShape(Circle())
            .accessibilityLabel("Начать сканирование")
            .accessibilityHint("Нажмите на кнопку для начала сканирования")
        }
        .frame(width: containerSize, height: containerSize)
    }
}
struct IdleWelcomeView: View {
    let scannerStatus: BleScannerStatus
    let shouldShowScannerStatus: Bool
    let onStartScan: () -> Void

    private var hintText: String {
        if shouldShowScannerStatus {
            return "\(scannerStatus.title)\n\(scannerStatus.message)"
        }
        return "Нажмите на кнопку\nдля начала сканирования"
    }

    var body: some View {
        AndroidCenterLayout(
            title: "Добро пожаловать!",
            subtitle: "Это приложение для оплаты QR-кодов\nпо технологии Bluetooth Low Energy",
            bottomHint: hintText,
            visualTopSpacing: 48,
            visual: { BluetoothHeroScanButton(action: onStartScan) }
        )
    }
}
