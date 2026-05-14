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
        case .timeoutError:
            return Self(scannerStatus: statusPresenter.status(for: .ready, isScanning: false), flowState: .scannerUnavailable(message: "Терминал не найден. Попробуйте повторить сканирование."), isScanning: false, scannerState: .ready, diagnostics: [HomeDemoScenario.sampleAdvertisement], latestParseRejection: nil, canShowScanButtons: false, canStartScanAction: false, canStopScanAction: false, isLiveMode: false)
        case .error:
            return Self(scannerStatus: statusPresenter.status(for: .ready, isScanning: false), flowState: .paymentError(sample, message: "Payment service unavailable"), isScanning: false, scannerState: .ready, diagnostics: [HomeDemoScenario.sampleAdvertisement], latestParseRejection: nil, canShowScanButtons: false, canStartScanAction: false, canStopScanAction: false, isLiveMode: false)
        }
    }
    #endif
}
