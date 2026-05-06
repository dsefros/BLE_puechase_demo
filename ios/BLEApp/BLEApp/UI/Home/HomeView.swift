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

            AndroidParityBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                mainStateView
                    .id(presentation.transitionKey)
                    .transition(transition(for: presentation.flowState))
                    .animation(animation(for: presentation.flowState), value: presentation.transitionKey)
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
                scannerStatus: presentation.scannerStatus,
                shouldShowScannerStatus: !presentation.canStartScanAction,
                onStartScan: handleStartScanTap
            )
        case .scanning:
            ScanningStateView(
                onCancel: handleCancelTap,
                isEnabled: canInteractWithCurrentPresentation
            )
        case .readyForConfirmation(let candidate):
            CandidateConfirmationView(
                candidate: candidate,
                formatAmount: formatAmount,
                onConfirm: handleConfirmTap,
                onCancel: handleCancelTap,
                isEnabled: canInteractWithCurrentPresentation
            )
        case .submittingPayment(let candidate):
            SubmittingPaymentView(candidate: candidate, formatAmount: formatAmount)
        case .paymentSuccess(let candidate):
            PaymentSuccessView(
                candidate: candidate,
                formatAmount: formatAmount,
                onDone: handleDoneTap,
                isEnabled: canInteractWithCurrentPresentation
            )
        case .paymentError(let candidate, let message):
            PaymentErrorView(
                candidate: candidate,
                message: message,
                formatAmount: formatAmount,
                onRetry: handleRetryTap,
                isEnabled: canInteractWithCurrentPresentation
            )
        case .scannerUnavailable(let message):
            ScannerUnavailableView(
                message: scannerStatusMessage(fallback: message),
                onBack: handleRetryTap,
                isEnabled: canInteractWithCurrentPresentation
            )
        case .blockingError(let message):
            BlockingErrorView(
                message: scannerStatusMessage(fallback: message),
                onBack: handleRetryTap,
                isEnabled: canInteractWithCurrentPresentation
            )
        }
    }

    private func transition(for state: PaymentFlowState) -> AnyTransition {
        switch state {
        case .scanning:
            return .asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.9)),
                removal: .opacity.combined(with: .scale(scale: 0.95))
            )
        case .readyForConfirmation:
            return .asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .opacity.combined(with: .scale(scale: 0.98))
            )
        case .paymentSuccess:
            return .opacity.combined(with: .scale(scale: 0.96))
        case .paymentError, .scannerUnavailable, .blockingError:
            return .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
        default:
            return .opacity
        }
    }

    private func animation(for state: PaymentFlowState) -> Animation {
        switch state {
        case .scanning:
            return .easeInOut(duration: 0.30)
        case .readyForConfirmation:
            return .interpolatingSpring(stiffness: 180, damping: 24)
        case .paymentSuccess:
            return .easeInOut(duration: 0.50)
        case .paymentError, .scannerUnavailable, .blockingError:
            return .easeInOut(duration: 0.30)
        default:
            return .easeInOut(duration: 0.25)
        }
    }

    private var canInteractWithCurrentPresentation: Bool {
        #if DEBUG
        if demoScenario != .live {
            return true
        }
        #endif

        return presentation.isLiveMode
    }

    private func scannerStatusMessage(fallback: String) -> String {
        guard !presentation.scannerStatus.canStartScan else {
            return fallback
        }

        return "\(presentation.scannerStatus.title)\n\(presentation.scannerStatus.message)"
    }

    private func handleStartScanTap() {
        #if DEBUG
        if demoScenario != .live {
            if demoScenario == .ready {
                demoScenario = .scanning
            }
            return
        }
        #endif

        startScanIfLive()
    }

    private func handleCancelTap() {
        #if DEBUG
        if demoScenario != .live {
            demoScenario = .ready
            return
        }
        #endif

        if case .scanning = presentation.flowState {
            stopScanIfLive()
        } else {
            cancelConfirmationIfLive()
        }
    }

    private func handleConfirmTap() {
        #if DEBUG
        if demoScenario != .live {
            if demoScenario == .candidate {
                demoScenario = .submitting
            }
            return
        }
        #endif

        confirmPaymentIfLive()
    }

    private func handleDoneTap() {
        #if DEBUG
        if demoScenario != .live {
            demoScenario = .ready
            return
        }
        #endif

        cancelConfirmationIfLive()
    }

    private func handleRetryTap() {
        #if DEBUG
        if demoScenario != .live {
            demoScenario = .ready
            return
        }
        #endif

        cancelConfirmationIfLive()
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

private enum HomePalette {
    static let brandOrange = Color(red: 0.09, green: 0.44, blue: 0.78)
    static let brandBlack = Color.black
    static let brandDarkGray = Color(red: 0.39, green: 0.39, blue: 0.39)
    static let brandGreen = Color(red: 0.23, green: 0.74, blue: 0.37)
    static let brandRed = Color(red: 0.90, green: 0.20, blue: 0.20)
}

private struct AndroidParityBackground: View {
    var body: some View {
        LottieView(
            animationName: "background",
            loopMode: .loop,
            contentMode: .aspectFill,
            autoplay: true,
            fallback: { PaleWaveBackground() }
        )
        .overlay(Color.white.opacity(0.54))
        .blur(radius: 10)
    }
}

private struct PaleWaveBackground: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(HomePalette.brandOrange.opacity(0.07))
                .frame(width: 340, height: 340)
                .offset(x: -130, y: -260)

            Circle()
                .stroke(HomePalette.brandOrange.opacity(0.10), lineWidth: 30)
                .frame(width: 430, height: 430)
                .offset(x: 190, y: -290)

            RoundedRectangle(cornerRadius: 90, style: .continuous)
                .fill(HomePalette.brandOrange.opacity(0.05))
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
                .fill(HomePalette.brandOrange.opacity(0.18))
                .frame(width: 170, height: 170)
                .blur(radius: 2)

            Circle()
                .fill(Color.white)
                .frame(width: 132, height: 132)
                .shadow(color: HomePalette.brandOrange.opacity(0.20), radius: 18, x: 0, y: 8)

            BluetoothGlyph()
                .stroke(HomePalette.brandOrange, style: StrokeStyle(lineWidth: 7, lineCap: .round, lineJoin: .round))
                .frame(width: 58, height: 78)
        }
    }
}

private struct BluetoothHeroButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .shadow(
                color: HomePalette.brandOrange.opacity(configuration.isPressed ? 0.20 : 0.10),
                radius: configuration.isPressed ? 10 : 16,
                x: 0,
                y: configuration.isPressed ? 4 : 8
            )
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct BluetoothHeroScanButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                LottieView(
                    animationName: "bluetooth",
                    loopMode: .loop,
                    contentMode: .aspectFit,
                    autoplay: true,
                    fallback: { BluetoothHeroIcon() }
                )
                .frame(width: 380, height: 380)

                Circle()
                    .fill(Color.clear)
                    .frame(width: 150, height: 150)
                    .contentShape(Circle())
            }
            .frame(width: 380, height: 380)
            .contentShape(Circle())
        }
        .buttonStyle(BluetoothHeroButtonStyle())
        .accessibilityLabel("Начать сканирование")
        .accessibilityHint("Нажмите на значок Bluetooth для начала сканирования")
    }
}

private struct BluetoothGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let midX = rect.midX
        let topY = rect.minY + rect.height * 0.08
        let bottomY = rect.maxY - rect.height * 0.08
        let centerY = rect.midY
        let rightX = rect.maxX - rect.width * 0.18
        let leftX = rect.minX + rect.width * 0.18

        path.move(to: CGPoint(x: midX, y: topY))
        path.addLine(to: CGPoint(x: midX, y: bottomY))

        path.move(to: CGPoint(x: midX, y: topY))
        path.addLine(to: CGPoint(x: rightX, y: rect.minY + rect.height * 0.30))
        path.addLine(to: CGPoint(x: leftX, y: centerY))
        path.addLine(to: CGPoint(x: rightX, y: rect.maxY - rect.height * 0.30))
        path.addLine(to: CGPoint(x: midX, y: bottomY))

        path.move(to: CGPoint(x: leftX, y: rect.minY + rect.height * 0.30))
        path.addLine(to: CGPoint(x: midX, y: centerY))
        path.addLine(to: CGPoint(x: leftX, y: rect.maxY - rect.height * 0.30))

        return path
    }
}

private struct BluePrimaryButton: View {
    let title: String
    let action: () -> Void
    let isEnabled: Bool

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .foregroundStyle(.white)
                .background(isEnabled ? HomePalette.brandOrange : HomePalette.brandOrange.opacity(0.35))
                .clipShape(Capsule())
        }
        .disabled(!isEnabled)
        .padding(.horizontal, 28)
        .padding(.bottom, 18)
    }
}

private struct IdleWelcomeView: View {
    let scannerStatus: BleScannerStatus
    let shouldShowScannerStatus: Bool
    let onStartScan: () -> Void

    private var hintText: String {
        if shouldShowScannerStatus {
            return "\(scannerStatus.title)\n\(scannerStatus.message)"
        }

        return "Нажмите на значок Bluetooth для начала сканирования"
    }

    var body: some View {
        StateContainer(
            title: "Добро пожаловать!",
            subtitle: "Это приложение для оплаты QR-кодов по технологии Bluetooth Low Energy",
            bottomHint: hintText,
            visual: { BluetoothHeroScanButton(action: onStartScan) }
        )
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
        LottieView(
            animationName: "loader",
            loopMode: .loop,
            contentMode: .aspectFit,
            autoplay: true,
            fallback: { DotsLoaderFallback() }
        )
        .frame(width: 380, height: 380)
    }
}

private struct DotsLoaderFallback: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSinceReferenceDate
            let activeDot = Int((elapsed / 0.35).truncatingRemainder(dividingBy: 3))

            HStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(HomePalette.brandOrange.opacity(activeDot == index ? 1.0 : 0.30))
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
    let isEnabled: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Button(action: onCancel) {
                    Text("‹")
                        .font(.system(size: 34, weight: .regular))
                        .foregroundStyle(HomePalette.brandBlack)
                        .frame(width: 44, height: 44)
                }
                .disabled(!isEnabled)
                .accessibilityLabel("Назад")

                Text("Подтверждение платежа")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(HomePalette.brandBlack)

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)

            Spacer(minLength: 18)

            VStack(spacing: 22) {
                LottieView(
                    animationName: "store_animated",
                    loopMode: .loop,
                    contentMode: .aspectFit,
                    autoplay: true,
                    fallback: { BluetoothHeroIcon() }
                )
                .frame(width: 200, height: 200)

                ConfirmationSection(label: "Магазин", value: candidate.merchant.isEmpty ? "—" : candidate.merchant)

                Divider()

                ConfirmationSection(label: "Сумма к оплате", value: formatAmount(candidate.amountMinor), isAmount: true)

                #if DEBUG
                Text("QRC ID: \(candidate.qrcID)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                #endif
            }
            .padding(32)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(0.12), radius: 18, x: 0, y: 10)
            .padding(.horizontal, 28)

            Spacer(minLength: 18)

            BluePrimaryButton(title: "Оплатить \(formatAmount(candidate.amountMinor))", action: onConfirm, isEnabled: isEnabled)
        }
    }
}

private struct ConfirmationSection: View {
    let label: String
    let value: String
    var isAmount: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(HomePalette.brandOrange)
                .tracking(0.5)

            Text(value)
                .font(.system(size: isAmount ? 30 : 22, weight: isAmount ? .black : .bold))
                .foregroundStyle(isAmount ? HomePalette.brandBlack : HomePalette.brandDarkGray)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct SubmittingPaymentView: View {
    let candidate: PaymentCandidate
    let formatAmount: (UInt32) -> String

    var body: some View {
        StateContainer(
            title: "Пожалуйста, подождите",
            subtitle: "отправка платежа...",
            bottomHint: nil,
            visual: { ScanningLoaderView() }
        )
        .accessibilityHint("Платеж для \(candidate.merchant), сумма \(formatAmount(candidate.amountMinor))")
    }
}

private struct PaymentSuccessView: View {
    let candidate: PaymentCandidate
    let formatAmount: (UInt32) -> String
    let onDone: () -> Void
    let isEnabled: Bool

    @State private var progress: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            Text("Одобрено")
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(HomePalette.brandGreen)
                .multilineTextAlignment(.center)

            Spacer().frame(height: 80)

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

            Spacer().frame(height: 56)

            Text("Оплата")
                .font(.system(size: 16, weight: .regular))
                .tracking(0.8)
                .foregroundStyle(HomePalette.brandDarkGray)

            Text(formatAmount(candidate.amountMinor))
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(HomePalette.brandBlack)
                .padding(.top, 8)

            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(HomePalette.brandGreen)
                .frame(maxWidth: 220)
                .padding(.top, 24)

            Text("Возврат на главный экран...")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(HomePalette.brandDarkGray)
                .padding(.top, 8)

            Spacer(minLength: 18)

            BluePrimaryButton(title: "Готово", action: onDone, isEnabled: isEnabled)
        }
        .padding(.horizontal, 28)
        .onAppear {
            progress = 0
            withAnimation(.linear(duration: 5)) {
                progress = 1
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard !Task.isCancelled, isEnabled else { return }
            onDone()
        }
    }
}

private struct PaymentErrorView: View {
    let candidate: PaymentCandidate
    let message: String
    let formatAmount: (UInt32) -> String
    let onRetry: () -> Void
    let isEnabled: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: onRetry) {
                    Text("×")
                        .font(.system(size: 28, weight: .regular))
                        .foregroundStyle(HomePalette.brandDarkGray)
                        .frame(width: 44, height: 44)
                }
                .disabled(!isEnabled)
                .accessibilityLabel("На главный экран")
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)

            Spacer(minLength: 24)

            Text("Ошибка оплаты")
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(HomePalette.brandRed)
                .multilineTextAlignment(.center)

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
            .frame(width: 250, height: 250)
            .padding(.top, 22)

            Text("\(candidate.merchant)\n\(formatAmount(candidate.amountMinor))")
                .font(.system(size: 14, weight: .regular))
                .lineSpacing(8)
                .foregroundStyle(HomePalette.brandBlack)
                .multilineTextAlignment(.center)
                .padding(.top, 10)

            Text(message)
                .font(.system(size: 14, weight: .regular))
                .lineSpacing(6)
                .foregroundStyle(HomePalette.brandDarkGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .padding(.top, 14)

            Spacer(minLength: 24)

            BluePrimaryButton(title: "Повторить", action: onRetry, isEnabled: isEnabled)
        }
    }
}

private struct ScannerUnavailableView: View {
    let message: String
    let onBack: () -> Void
    let isEnabled: Bool

    var body: some View {
        VStack(spacing: 0) {
            StateContainer(
                title: "Сканер недоступен",
                subtitle: message,
                bottomHint: nil,
                visual: { BluetoothHeroIcon() }
            )

            BluePrimaryButton(title: "Назад", action: onBack, isEnabled: isEnabled)
        }
    }
}

private struct BlockingErrorView: View {
    let message: String
    let onBack: () -> Void
    let isEnabled: Bool

    var body: some View {
        VStack(spacing: 0) {
            StateContainer(
                title: "Требуется действие",
                subtitle: message,
                bottomHint: nil,
                visual: { BluetoothHeroIcon() }
            )

            BluePrimaryButton(title: "Назад", action: onBack, isEnabled: isEnabled)
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

    var transitionKey: String {
        switch flowState {
        case .idle:
            return "idle"
        case .scanning:
            return "scanning"
        case .readyForConfirmation:
            return "readyForConfirmation"
        case .submittingPayment:
            return "submittingPayment"
        case .paymentSuccess:
            return "paymentSuccess"
        case .paymentError:
            return "paymentError"
        case .scannerUnavailable:
            return "scannerUnavailable"
        case .blockingError:
            return "blockingError"
        }
    }

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
