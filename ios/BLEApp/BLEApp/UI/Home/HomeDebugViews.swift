import SwiftUI

#if DEBUG
struct AndroidParitySettingsView: View {
    @Binding var isAutoScanEnabled: Bool
    @Binding var showDeveloperPanel: Bool
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
                        Text("Локальный DEBUG-переключатель; production-поведение не меняется")
                            .font(.system(size: 12, weight: .regular))
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

                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Debug-панель")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(HomePalette.brandBlack)
                        Text("Показывать локальные сценарии и диагностику только для разработки")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                    Toggle("", isOn: $showDeveloperPanel)
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
                    Text("Версия 1.0.0 (by DEfros and EAks)")
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

struct DiagnosticsSection: View {
    let presentation: HomeScreenPresentation

    var body: some View {
        DisclosureGroup("DEBUG diagnostics") {
            VStack(alignment: .leading, spacing: 6) {
                Text("Scanner state: \(presentation.scannerState.rawValue)")
                if let rejection = presentation.latestParseRejection {
                    Text("Latest parse rejection: \(rejection)")
                }
                Text("Captured advertisements: \(presentation.diagnostics.count)")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .padding(.top, 8)
        }
        .font(.caption)
        .padding(10)
        .background(Color(.secondarySystemBackground).opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct DemoScenarioPicker: View {
    @Binding var scenario: HomeDemoScenario

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Demo scenario (DEBUG)")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(.secondary)
            Picker("Scenario", selection: $scenario) {
                ForEach(HomeDemoScenario.allCases) { item in
                    Text(item.title).tag(item)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(.secondarySystemBackground).opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
#endif
