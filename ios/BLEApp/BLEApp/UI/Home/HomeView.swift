import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel

    #if DEBUG
    @State private var demoScenario: HomeDemoScenario = .live
    #endif

    private var presentation: HomeScreenPresentation {
        #if DEBUG
        if demoScenario != .live {
            return HomeScreenPresentation.demo(demoScenario)
        }
        #endif

        return HomeScreenPresentation.live(from: viewModel)
    }

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            PaleWaveBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                mainStateView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                #if DEBUG
                DemoScenarioPicker(scenario: $demoScenario)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
                #endif

                #if DEBUG
                DiagnosticsSection(presentation: presentation)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                #endif
            }
        }
    }

    @ViewBuilder
    private var mainStateView: some View {
        switch presentation.flowState {
        case .idle:
            IdleWelcomeView(
                onStartScan: startScanIfLive,
                isEnabled: presentation.canStartScanAction && presentation.isLiveMode
            )
        case .scanning:
            ScanningStateView(
                onCancel: stopScanIfLive,
                isEnabled: presentation.canStopScanAction && presentation.isLiveMode
            )
        case .readyForConfirmation(let candidate):
            CandidateConfirmationView(
                candidate: candidate,
                formatAmount: formatAmount,
                onConfirm: confirmPaymentIfLive,
                onCancel: cancelConfirmationIfLive,
                isLiveMode: presentation.isLiveMode
            )
        case .submittingPayment(let candidate):
            SubmittingPaymentView(candidate: candidate, formatAmount: formatAmount)
        case .paymentSuccess(let candidate):
            PaymentSuccessView(
                candidate: candidate,
                formatAmount: formatAmount,
                onDone: cancelConfirmationIfLive,
                isLiveMode: presentation.isLiveMode
            )
        case .paymentError(let candidate, let message):
            PaymentErrorView(
                candidate: candidate,
                message: message,
                formatAmount: formatAmount,
                onRetry: cancelConfirmationIfLive,
                isLiveMode: presentation.isLiveMode
            )
        case .scannerUnavailable(let message):
            ScannerUnavailableView(message: message, onBack: cancelConfirmationIfLive, isLiveMode: presentation.isLiveMode)
        case .blockingError(let message):
            BlockingErrorView(message: message, onBack: cancelConfirmationIfLive, isLiveMode: presentation.isLiveMode)
        }
    }

    private func confirmPaymentIfLive() {
        guard presentation.isLiveMode else { return }
        Task { await viewModel.confirmPayment() }
    }

    private func cancelConfirmationIfLive() {
        guard presentation.isLiveMode else { return }
        viewModel.cancelConfirmation()
    }

    private func startScanIfLive() {
        guard presentation.isLiveMode else { return }
        viewModel.startScan()
    }

    private func stopScanIfLive() {
        guard presentation.isLiveMode else { return }
        viewModel.stopScan()
    }

    func formatAmount(_ amountMinor: UInt32) -> String {
        let rubles = amountMinor / 100
        let kopecks = amountMinor % 100
        return "\(rubles) RUB \(String(format: "%02d", kopecks)) kop"
    }
}

private struct PaleWaveBackground: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.07))
                .frame(width: 340, height: 340)
                .offset(x: -130, y: -260)

            Circle()
                .stroke(Color.blue.opacity(0.10), lineWidth: 30)
                .frame(width: 430, height: 430)
                .offset(x: 190, y: -290)

            RoundedRectangle(cornerRadius: 90, style: .continuous)
                .fill(Color.blue.opacity(0.05))
                .frame(width: 520, height: 170)
                .rotationEffect(.degrees(-17))
                .offset(x: -70, y: 250)
        }
    }
}

private struct StateContainer<Content: View>: View {
    let title: String
    let subtitle: String
    let bottomHint: String?
    @ViewBuilder let visual: Content

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            VStack(spacing: 18) {
                visual
                Text(title)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Color.black)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color(.darkGray))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)

                if let bottomHint {
                    Text(bottomHint)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Color(.gray))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 18)
                        .padding(.top, 4)
                }
            }

            Spacer(minLength: 24)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }
}

private struct BluetoothHeroIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.18))
                .frame(width: 170, height: 170)
                .blur(radius: 2)

            Circle()
                .fill(Color.white)
                .frame(width: 132, height: 132)
                .shadow(color: Color.blue.opacity(0.20), radius: 18, x: 0, y: 8)

            Image(systemName: "bluetooth")
                .font(.system(size: 58, weight: .semibold))
                .foregroundStyle(Color.blue)
        }
    }
}

private struct BluePrimaryButton: View {
    let title: String
    let action: () -> Void
    let isEnabled: Bool

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundStyle(.white)
                .background(isEnabled ? Color.blue : Color.blue.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .disabled(!isEnabled)
        .padding(.horizontal, 20)
        .padding(.bottom, 22)
    }
}

private struct IdleWelcomeView: View {
    let onStartScan: () -> Void
    let isEnabled: Bool

    var body: some View {
        VStack(spacing: 0) {
            StateContainer(
                title: "Добро пожаловать!",
                subtitle: "Это приложение для оплаты QR-кодов по технологии Bluetooth Low Energy",
                bottomHint: "Нажмите на кнопку для начала сканирования",
                visual: { BluetoothHeroIcon() }
            )

            BluePrimaryButton(title: "Начать сканирование", action: onStartScan, isEnabled: isEnabled)
        }
    }
}

private struct ScanningStateView: View {
    let onCancel: () -> Void
    let isEnabled: Bool

    var body: some View {
        VStack(spacing: 0) {
            StateContainer(
                title: "Пожалуйста, подождите",
                subtitle: "Сканирование...",
                bottomHint: nil,
                visual: { ScanningLoaderView() }
            )

            BluePrimaryButton(title: "Отмена", action: onCancel, isEnabled: isEnabled)
        }
    }
}

private struct ScanningLoaderView: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSinceReferenceDate
            let activeDot = Int((elapsed / 0.35).truncatingRemainder(dividingBy: 3))

            HStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.blue.opacity(activeDot == index ? 1.0 : 0.30))
                        .frame(width: activeDot == index ? 14 : 11, height: activeDot == index ? 14 : 11)
                        .animation(.easeInOut(duration: 0.2), value: activeDot)
                }
            }
        }
        .padding(30)
    }
}

private struct CandidateConfirmationView: View {
    let candidate: PaymentCandidate
    let formatAmount: (UInt32) -> String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    let isLiveMode: Bool

    var body: some View {
        VStack(spacing: 0) {
            StateContainer(
                title: "Подтвердите оплату",
                subtitle: "\(candidate.merchant)\n\(formatAmount(candidate.amountMinor))",
                bottomHint: nil,
                visual: { BluetoothHeroIcon() }
            )

            VStack(spacing: 10) {
                BluePrimaryButton(title: "Подтвердить", action: onConfirm, isEnabled: isLiveMode)
                Button("Отмена", action: onCancel)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.blue)
                    .padding(.bottom, 20)
            }
        }
    }
}

private struct SubmittingPaymentView: View {
    let candidate: PaymentCandidate
    let formatAmount: (UInt32) -> String

    var body: some View {
        StateContainer(
            title: "Оплата выполняется",
            subtitle: "\(candidate.merchant)\n\(formatAmount(candidate.amountMinor))",
            bottomHint: "Пожалуйста, не закрывайте приложение",
            visual: { ProgressView().scaleEffect(1.4).tint(.blue) }
        )
    }
}

private struct PaymentSuccessView: View {
    let candidate: PaymentCandidate
    let formatAmount: (UInt32) -> String
    let onDone: () -> Void
    let isLiveMode: Bool

    var body: some View {
        VStack(spacing: 0) {
            StateContainer(
                title: "Оплата успешна",
                subtitle: "\(candidate.merchant)\n\(formatAmount(candidate.amountMinor))",
                bottomHint: nil,
                visual: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 110))
                        .foregroundStyle(Color.blue)
                }
            )

            BluePrimaryButton(title: "Готово", action: onDone, isEnabled: isLiveMode)
        }
    }
}

private struct PaymentErrorView: View {
    let candidate: PaymentCandidate
    let message: String
    let formatAmount: (UInt32) -> String
    let onRetry: () -> Void
    let isLiveMode: Bool

    var body: some View {
        VStack(spacing: 0) {
            StateContainer(
                title: "Ошибка оплаты",
                subtitle: "\(candidate.merchant)\n\(formatAmount(candidate.amountMinor))",
                bottomHint: message,
                visual: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 110))
                        .foregroundStyle(Color.blue)
                }
            )

            BluePrimaryButton(title: "Повторить", action: onRetry, isEnabled: isLiveMode)
        }
    }
}

private struct ScannerUnavailableView: View {
    let message: String
    let onBack: () -> Void
    let isLiveMode: Bool

    var body: some View {
        VStack(spacing: 0) {
            StateContainer(
                title: "Сканер недоступен",
                subtitle: message,
                bottomHint: nil,
                visual: { BluetoothHeroIcon() }
            )

            BluePrimaryButton(title: "Назад", action: onBack, isEnabled: isLiveMode)
        }
    }
}

private struct BlockingErrorView: View {
    let message: String
    let onBack: () -> Void
    let isLiveMode: Bool

    var body: some View {
        VStack(spacing: 0) {
            StateContainer(
                title: "Требуется действие",
                subtitle: message,
                bottomHint: nil,
                visual: { BluetoothHeroIcon() }
            )

            BluePrimaryButton(title: "Назад", action: onBack, isEnabled: isLiveMode)
        }
    }
}

#if DEBUG
private struct DiagnosticsSection: View {
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
#endif

struct HomeScreenPresentation {
    let scannerStatus: BleScannerStatus
    let flowState: PaymentFlowState
    let isScanning: Bool
    let scannerState: BleScannerState
    let diagnostics: [BleDiscoveredAdvertisement]
    let latestParseRejection: String?
    let canShowScanButtons: Bool
    let canStartScanAction: Bool
    let canStopScanAction: Bool
    let isLiveMode: Bool

    @MainActor
    static func live(from viewModel: HomeViewModel) -> Self {
        Self(
            scannerStatus: viewModel.scannerStatus,
            flowState: viewModel.flowState,
            isScanning: viewModel.isScanning,
            scannerState: viewModel.scannerState,
            diagnostics: Array(viewModel.discoveredAdvertisements.prefix(5)),
            latestParseRejection: viewModel.latestParseRejection,
            canShowScanButtons: viewModel.canShowScanButtons,
            canStartScanAction: viewModel.canStartScanAction,
            canStopScanAction: viewModel.canStopScanAction,
            isLiveMode: true
        )
    }

    #if DEBUG
    static func demo(_ scenario: HomeDemoScenario) -> Self {
        let statusPresenter = BleScannerStatusPresenter()
        let sample = HomeDemoScenario.sampleCandidate

        switch scenario {
        case .live:
            return Self(scannerStatus: statusPresenter.status(for: .ready, isScanning: false), flowState: .idle, isScanning: false, scannerState: .ready, diagnostics: [], latestParseRejection: nil, canShowScanButtons: true, canStartScanAction: true, canStopScanAction: false, isLiveMode: true)
        case .unsupported:
            return Self(scannerStatus: statusPresenter.status(for: .unsupported, isScanning: false), flowState: .scannerUnavailable(message: "Bluetooth LE is unsupported on this device."), isScanning: false, scannerState: .unsupported, diagnostics: [HomeDemoScenario.sampleAdvertisement], latestParseRejection: "Missing Volna service/manufacturer data", canShowScanButtons: false, canStartScanAction: false, canStopScanAction: false, isLiveMode: false)
        case .ready:
            return Self(scannerStatus: statusPresenter.status(for: .ready, isScanning: false), flowState: .idle, isScanning: false, scannerState: .ready, diagnostics: [HomeDemoScenario.sampleAdvertisement], latestParseRejection: nil, canShowScanButtons: true, canStartScanAction: true, canStopScanAction: false, isLiveMode: false)
        case .scanning:
            return Self(scannerStatus: statusPresenter.status(for: .scanning, isScanning: true), flowState: .scanning, isScanning: true, scannerState: .scanning, diagnostics: [HomeDemoScenario.sampleAdvertisement], latestParseRejection: nil, canShowScanButtons: true, canStartScanAction: false, canStopScanAction: true, isLiveMode: false)
        case .candidate:
            return Self(scannerStatus: statusPresenter.status(for: .ready, isScanning: false), flowState: .readyForConfirmation(sample), isScanning: false, scannerState: .ready, diagnostics: [HomeDemoScenario.sampleAdvertisement], latestParseRejection: nil, canShowScanButtons: false, canStartScanAction: false, canStopScanAction: false, isLiveMode: false)
        case .submitting:
            return Self(scannerStatus: statusPresenter.status(for: .ready, isScanning: false), flowState: .submittingPayment(sample), isScanning: false, scannerState: .ready, diagnostics: [HomeDemoScenario.sampleAdvertisement], latestParseRejection: nil, canShowScanButtons: false, canStartScanAction: false, canStopScanAction: false, isLiveMode: false)
        case .success:
            return Self(scannerStatus: statusPresenter.status(for: .ready, isScanning: false), flowState: .paymentSuccess(sample), isScanning: false, scannerState: .ready, diagnostics: [HomeDemoScenario.sampleAdvertisement], latestParseRejection: nil, canShowScanButtons: false, canStartScanAction: false, canStopScanAction: false, isLiveMode: false)
        case .error:
            return Self(scannerStatus: statusPresenter.status(for: .ready, isScanning: false), flowState: .paymentError(sample, message: "Payment service unavailable"), isScanning: false, scannerState: .ready, diagnostics: [HomeDemoScenario.sampleAdvertisement], latestParseRejection: nil, canShowScanButtons: false, canStartScanAction: false, canStopScanAction: false, isLiveMode: false)
        }
    }
    #endif
}

#if DEBUG
enum HomeDemoScenario: String, CaseIterable, Identifiable {
    case live
    case unsupported
    case ready
    case scanning
    case candidate
    case submitting
    case success
    case error

    var id: String { rawValue }

    var title: String {
        switch self {
        case .live: return "Live"
        case .unsupported: return "Unsupported"
        case .ready: return "Ready"
        case .scanning: return "Scanning"
        case .candidate: return "Candidate"
        case .submitting: return "Submitting"
        case .success: return "Success"
        case .error: return "Error"
        }
    }

    static var sampleCandidate: PaymentCandidate {
        PaymentCandidate(merchant: "Demo Merchant", amountMinor: 12345, qrcID: "DEMO123", rssi: -55, finalRSSI: -57, rssiDelta: 2, peripheralID: UUID(), peripheralName: "Demo BLE Terminal", timestamp: Date(timeIntervalSince1970: 1_700_000_000))
    }

    static var sampleAdvertisement: BleDiscoveredAdvertisement {
        BleDiscoveredAdvertisement(peripheralID: UUID(), peripheralName: "Demo BLE Terminal", rssi: -55, serviceUUIDs: [BleConfig.serviceUUIDString], volnaServiceData: Data([0x20, 0x80, 0x01, 0x01]), manufacturerData: Data([0x01, 0xF0, 0x00, 0x00]), timestamp: Date(timeIntervalSince1970: 1_700_000_100))
    }
}

private struct DemoScenarioPicker: View {
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
