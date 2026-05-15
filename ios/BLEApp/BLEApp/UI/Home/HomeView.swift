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
                .buttonStyle(.plain)
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

    private static let rubFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.numberStyle = .currency
        formatter.currencyCode = "RUB"
        formatter.currencySymbol = "₽"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    func formatAmount(_ amountMinor: UInt32) -> String {
        Self.rubFormatter.string(from: NSNumber(value: Double(amountMinor) / 100.0)) ?? "0,00 ₽"
    }
}
