import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel

    #if DEBUG
    @State private var demoScenario: HomeDemoScenario = .live
    @State private var showSettings = false
    @State private var isAutoScanEnabled = false
    @State private var showDeveloperPanel = false
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

            #if DEBUG
            if showSettings {
                AndroidParitySettingsView(
                    isAutoScanEnabled: $isAutoScanEnabled,
                    showDeveloperPanel: $showDeveloperPanel,
                    onBack: { withAnimation(.easeInOut(duration: 0.20)) { showSettings = false } }
                )
                .transition(.opacity)
            } else {
                appContent
                    .transition(.opacity)
            }
            #else
            appContent
            #endif
        }
    }

    private var appContent: some View {
        VStack(spacing: 0) {
            mainStateView
                .id(presentation.transitionKey)
                .transition(transition(for: presentation.flowState))
                .animation(animation(for: presentation.flowState), value: presentation.transitionKey)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            #if DEBUG
            if showDeveloperPanel {
                DemoScenarioPicker(scenario: $demoScenario)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)

                DiagnosticsSection(presentation: presentation)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
            #endif
        }
        .overlay(alignment: .topTrailing) {
            #if DEBUG
            if presentation.flowState == .idle {
                Button {
                    withAnimation(.easeInOut(duration: 0.20)) { showSettings = true }
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(HomePalette.brandDarkGray)
                        .frame(width: 44, height: 44)
                }
                .padding(.top, 48)
                .padding(.trailing, 16)
                .accessibilityLabel("Настройки")
            }
            #endif
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
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.numberStyle = .currency
        formatter.currencyCode = "RUB"
        formatter.currencySymbol = "₽"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: Double(amountMinor) / 100.0)) ?? "0,00 ₽"
    }
}

private enum HomePalette {
    static let brandOrange = Color(hex: 0x176FC6)
    static let brandBlack = Color(hex: 0x000000)
    static let brandGray = Color(hex: 0xD7E6EA)
    static let brandDarkGray = Color(hex: 0x2C2C2C)
    static let brandGreen = Color(hex: 0x27B648)
    static let brandRed = Color(hex: 0xEA002F)
    static let white = Color(hex: 0xFFFFFF)
    static let overlay = Color(red: 235 / 255, green: 235 / 255, blue: 235 / 255, opacity: 0.50)
    static let brandLightGray = Color(hex: 0xE9F1F3)
    static let settingsCard = Color(hex: 0xF5F5F5)
}

private extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }
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
        .blur(radius: 10)
        .overlay(HomePalette.overlay)
    }
}

private struct PaleWaveBackground: View {
    var body: some View {
        ZStack {
            HomePalette.brandGray.opacity(0.40)
            Circle()
                .fill(HomePalette.brandOrange.opacity(0.08))
                .frame(width: 420, height: 420)
                .offset(x: -150, y: -260)
            Circle()
                .stroke(HomePalette.brandOrange.opacity(0.10), lineWidth: 34)
                .frame(width: 520, height: 520)
                .offset(x: 190, y: -290)
            RoundedRectangle(cornerRadius: 90, style: .continuous)
                .fill(HomePalette.brandOrange.opacity(0.06))
                .frame(width: 560, height: 180)
                .rotationEffect(.degrees(-17))
                .offset(x: -70, y: 250)
        }
    }
}

private struct AndroidCenterLayout<Visual: View>: View {
    let title: String
    let subtitle: String?
    let status: String?
    let bottomHint: String?
    let titleColor: Color
    let titleMaxLines: Int?
    let visualTopSpacing: CGFloat
    let statusTopSpacing: CGFloat
    @ViewBuilder let visual: Visual

    init(
        title: String,
        subtitle: String? = nil,
        status: String? = nil,
        bottomHint: String? = nil,
        titleColor: Color = HomePalette.brandBlack,
        titleMaxLines: Int? = nil,
        visualTopSpacing: CGFloat = 16,
        statusTopSpacing: CGFloat = 32,
        @ViewBuilder visual: () -> Visual
    ) {
        self.title = title
        self.subtitle = subtitle
        self.status = status
        self.bottomHint = bottomHint
        self.titleColor = titleColor
        self.titleMaxLines = titleMaxLines
        self.visualTopSpacing = visualTopSpacing
        self.statusTopSpacing = statusTopSpacing
        self.visual = visual()
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 32)

            Text(title)
                .font(.system(size: 24, weight: .black))
                .lineSpacing(8)
                .foregroundStyle(titleColor)
                .multilineTextAlignment(.center)
                .lineLimit(titleMaxLines)
                .minimumScaleFactor(0.86)

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .lineSpacing(6)
                    .foregroundStyle(HomePalette.brandDarkGray)
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)
            }

            visual
                .padding(.top, visualTopSpacing)

            if let status {
                Text(status)
                    .font(.system(size: 14, weight: .regular))
                    .tracking(0.8)
                    .foregroundStyle(HomePalette.brandBlack)
                    .multilineTextAlignment(.center)
                    .padding(.top, statusTopSpacing)
            }

            if let bottomHint {
                Text(bottomHint)
                    .font(.system(size: 14, weight: .regular))
                    .lineSpacing(10)
                    .foregroundStyle(HomePalette.brandBlack)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }

            Spacer(minLength: 32)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 22)
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
                .fill(HomePalette.white)
                .frame(width: 132, height: 132)
                .shadow(color: HomePalette.brandOrange.opacity(0.20), radius: 18, x: 0, y: 8)
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 58, weight: .semibold))
                .foregroundStyle(HomePalette.brandOrange)
        }
    }
}

private struct BluetoothHeroScanButton: View {
    let action: () -> Void

    var body: some View {
        ZStack {
            LottieView(
                animationName: "bluetooth",
                loopMode: .loop,
                contentMode: .aspectFit,
                autoplay: true,
                fallback: { BluetoothHeroIcon() }
            )
            .frame(width: 380, height: 380)
            .allowsHitTesting(false)

            Button(action: action) {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 150, height: 150)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .frame(width: 150, height: 150)
            .contentShape(Circle())
            .accessibilityLabel("Начать сканирование")
            .accessibilityHint("Нажмите на кнопку для начала сканирования")
        }
        .frame(width: 380, height: 380)
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
                .frame(height: 56)
                .foregroundStyle(HomePalette.white)
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
        return "Нажмите на кнопку\nдля начала сканирования"
    }

    var body: some View {
        AndroidCenterLayout(
            title: "Добро пожаловать!",
            subtitle: "Это приложение для оплаты QR-кодов\nпо технологии Bluetooth Low Energy",
            bottomHint: hintText,
            visualTopSpacing: 8,
            visual: { BluetoothHeroScanButton(action: onStartScan) }
        )
    }
}

private struct ScanningStateView: View {
    let onCancel: () -> Void
    let isEnabled: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            AndroidCenterLayout(
                title: "Пожалуйста, подождите",
                status: "Сканирование...",
                titleMaxLines: 1,
                visualTopSpacing: 16,
                statusTopSpacing: 32,
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
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    Button(action: onCancel) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundStyle(HomePalette.brandBlack)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .disabled(!isEnabled)
                    .accessibilityLabel("Назад")

                    Text("Подтверждение платежа")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(HomePalette.brandBlack)

                    Spacer()
                }
                .padding(.vertical, 12)

                Spacer().frame(height: 24)

                VStack(spacing: 0) {
                    LottieView(
                        animationName: "store_animated",
                        loopMode: .loop,
                        contentMode: .aspectFit,
                        autoplay: true,
                        fallback: { BluetoothHeroIcon() }
                    )
                    .frame(width: 200, height: 200)
                    .padding(.bottom, 24)

                    ConfirmationSection(label: "Магазин", value: candidate.merchant.isEmpty ? "—" : candidate.merchant)

                    Spacer().frame(height: 12)
                    Divider().background(HomePalette.brandLightGray)
                    Spacer().frame(height: 12)

                    ConfirmationSection(label: "Сумма к оплате", value: formatAmount(candidate.amountMinor), isAmount: true)
                }
                .padding(32)
                .frame(maxWidth: .infinity)
                .background(HomePalette.white)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 8)
                .padding(.bottom, 16)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 18)

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
                .font(.system(size: isAmount ? 26 : 24, weight: isAmount ? .black : .bold))
                .lineSpacing(isAmount ? 14 : 6)
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
        AndroidCenterLayout(
            title: "Пожалуйста, подождите",
            status: "отправка платежа...",
            visualTopSpacing: 32,
            statusTopSpacing: 32,
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

private struct PaymentErrorView: View {
    let candidate: PaymentCandidate
    let message: String
    let formatAmount: (UInt32) -> String
    let onRetry: () -> Void
    let isEnabled: Bool

    var body: some View {
        AndroidErrorView(
            title: "Ошибка оплаты",
            message: message,
            onBack: onRetry,
            onRetry: onRetry,
            isEnabled: isEnabled
        )
        .accessibilityHint("Платеж для \(candidate.merchant), сумма \(formatAmount(candidate.amountMinor))")
    }
}

private struct ScannerUnavailableView: View {
    let message: String
    let onBack: () -> Void
    let isEnabled: Bool

    var body: some View {
        AndroidErrorView(title: "Ошибка", message: message, onBack: onBack, onRetry: onBack, isEnabled: isEnabled)
    }
}

private struct BlockingErrorView: View {
    let message: String
    let onBack: () -> Void
    let isEnabled: Bool

    var body: some View {
        AndroidErrorView(title: "Ошибка", message: message, onBack: onBack, onRetry: onBack, isEnabled: isEnabled)
    }
}

private struct AndroidErrorView: View {
    let title: String
    let message: String
    let onBack: () -> Void
    let onRetry: () -> Void
    let isEnabled: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: onBack) {
                        Image(systemName: "xmark")
                            .font(.system(size: 22, weight: .regular))
                            .foregroundStyle(HomePalette.brandDarkGray)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .disabled(!isEnabled)
                    .accessibilityLabel("На главный экран")
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Spacer(minLength: 24)

                Text(title)
                    .font(.system(size: 24, weight: .black))
                    .lineSpacing(8)
                    .foregroundStyle(HomePalette.brandRed)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer().frame(height: 32)

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

                Spacer().frame(height: 32)

                Text(message)
                    .font(.system(size: 14, weight: .regular))
                    .lineSpacing(10)
                    .foregroundStyle(HomePalette.brandBlack)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 22)

            BluePrimaryButton(title: "Повторить", action: onRetry, isEnabled: isEnabled)
        }
    }
}

#if DEBUG
private struct AndroidParitySettingsView: View {
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
#endif

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
