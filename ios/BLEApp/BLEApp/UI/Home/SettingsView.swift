import SwiftUI

struct SettingsView: View {
    @Binding var isAutoScanEnabled: Bool
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Button(action: onBack) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(HomePalette.brandBlack)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Назад")

                Text("Настройки")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(HomePalette.brandBlack)

                Spacer()
            }
            .padding(16)

            VStack(spacing: 16) {
                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Автоматическое сканирование")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(HomePalette.brandBlack)
                        Text("Запускать BLE-сканирование сразу после открытия приложения")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                    Toggle("", isOn: $isAutoScanEnabled)
                        .labelsHidden()
                        .tint(HomePalette.brandOrange)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(HomePalette.settingsCard)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.black.opacity(0.10), radius: 4, x: 0, y: 2)

                VStack(alignment: .leading, spacing: 8) {
                    Text("О приложении")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(HomePalette.brandBlack)
                    Text(AppVersionProvider.versionText)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.gray)
                    Text("Somers QR BLE")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(.gray)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(HomePalette.settingsCard)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.black.opacity(0.10), radius: 4, x: 0, y: 2)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}
