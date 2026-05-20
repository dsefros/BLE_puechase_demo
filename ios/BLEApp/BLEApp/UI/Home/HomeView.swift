import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    @AppStorage("autoScanEnabled") private var isAutoScanEnabled = false
    @State private var showSettings = false
    @State private var hasAttemptedAutoScanForIdleSession = false

    #if DEBUG
    @State private var demoScenario: HomeDemoScenario = .live
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
        foregroundContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Color(.systemBackground)
                    .ignoresSafeArea()

                AndroidParityBackground()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
    }

    private var foregroundContent: some View {
        Group {
            if showSettings {
                SettingsView(
                    isAutoScanEnabled: $isAutoScanEnabled,
                    onBack: closeSettings
                )
                .transition(.opacity)
            } else {
                appContent
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.20), value: showSettings)
        .task {
            resetAutoScanIdleAttempt()
            attemptAutoScan()
        }
        .onChange(of: isAutoScanEnabled) { isEnabled in
            handleAutoScanToggleChange(isEnabled: isEnabled)
        }
        .onChange(of: showSettings) { isShowingSettings in
            if !isShowingSettings {
                resetAutoScanIdleAttempt()
                attemptAutoScan()
            }
        }
        .onChange(of: viewModel.scannerState) { _ in
            handleScannerStateChangeForAutoScan()
        }
    }

    private var appContent: some View {
        VStack(spacing: 0) {
            mainStateView
                .id(presentation.transitionKey)
                .transition(transition(for: presentation.flowState))
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .overlay(alignment: .topTrailing) {
            if shouldShowSettingsGear {
                Button {
                    withAnimation(.easeInOut(duration: 0.20)) { showSettings = true }
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(HomePalette.brandDarkGray)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                #if DEBUG
                .simultaneousGesture(LongPressGesture().onEnded { _ in
                    showDeveloperPanel.toggle()
                })
                #endif
                .padding(.top, 48)
                .padding(.trailing, 16)
                .accessibilityLabel("Настройки")
            }
        }
    }

    private var shouldShowSettingsGear: Bool {
        switch presentation.flowState {
        case .idle, .scanning:
            return true
        default:
            return false
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
                onClose: handleCloseTap,
                onRetry: handleRetryTap,
                isEnabled: canInteractWithCurrentPresentation
            )
        case .scannerUnavailable(let message):
            ScannerUnavailableView(
                message: message,
                onClose: handleCloseTap,
                onRetry: handleRetryTap,
                isEnabled: canInteractWithCurrentPresentation
            )
        case .blockingError(let message):
            BlockingErrorView(
                message: message,
                onClose: handleCloseTap,
                onRetry: handleRetryTap,
                isEnabled: canInteractWithCurrentPresentation
            )
        }
    }

    private func transition(for state: PaymentFlowState) -> AnyTransition {
        switch state {
        case .scanning:
            return .identity
        case .readyForConfirmation:
            return .asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .opacity.combined(with: .scale(scale: 0.98))
            )
        case .paymentSuccess:
            return .opacity.combined(with: .scale(scale: 0.96))
        case .paymentError, .scannerUnavailable, .blockingError:
            return .identity
        default:
            return .opacity
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
            resetAutoScanIdleAttempt()
            attemptAutoScan()
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
        resetAutoScanIdleAttempt()
        attemptAutoScan()
    }

    private func handleRetryTap() {
        #if DEBUG
        if demoScenario != .live {
            demoScenario = .ready
            return
        }
        #endif

        retryCurrentErrorIfLive()
    }

    private func handleCloseTap() {
        #if DEBUG
        if demoScenario != .live {
            demoScenario = .ready
            return
        }
        #endif

        closeCurrentErrorIfLive()
        resetAutoScanIdleAttempt()
        attemptAutoScan()
    }

    private func confirmPaymentIfLive() {
        guard presentation.isLiveMode else { return }
        Task { await viewModel.confirmPayment() }
    }

    private func cancelConfirmationIfLive() {
        guard presentation.isLiveMode else { return }
        viewModel.cancelConfirmation()
    }

    private func retryCurrentErrorIfLive() {
        guard presentation.isLiveMode else { return }
        viewModel.retryCurrentError()
    }

    private func closeCurrentErrorIfLive() {
        guard presentation.isLiveMode else { return }
        viewModel.closeCurrentError()
    }

    private func startScanIfLive() {
        guard presentation.isLiveMode else { return }
        viewModel.startScan()
    }

    private func stopScanIfLive() {
        guard presentation.isLiveMode else { return }
        viewModel.stopScan()
    }

    private func closeSettings() {
        withAnimation(.easeInOut(duration: 0.20)) {
            showSettings = false
        }
    }

    private func handleAutoScanToggleChange(isEnabled: Bool) {
        resetAutoScanIdleAttempt()
        if isEnabled {
            attemptAutoScan()
        } else if case .scanning = presentation.flowState {
            stopScanIfLive()
        }
    }

    private func handleScannerStateChangeForAutoScan() {
        guard presentation.flowState == .idle, presentation.canStartScanAction else { return }
        resetAutoScanIdleAttempt()
        attemptAutoScan()
    }

    private func resetAutoScanIdleAttempt() {
        hasAttemptedAutoScanForIdleSession = false
    }

    private func attemptAutoScan() {
        guard isAutoScanEnabled,
              !hasAttemptedAutoScanForIdleSession,
              !showSettings,
              presentation.isLiveMode,
              presentation.flowState == .idle,
              presentation.canStartScanAction else { return }
        hasAttemptedAutoScanForIdleSession = true
        viewModel.startScan()
    }

    func formatAmount(_ amountMinor: UInt32) -> String {
        RussianCurrencyFormatter.formatAmount(amountMinor)
    }
}
