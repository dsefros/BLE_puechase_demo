import Foundation

struct AppContainer {
    let logger: AppLogger
    let prerequisitesChecker: PrerequisitesCheckingPlaceholder
    let scanner: BleScannerProtocol
    let validateSignalUseCase: ValidateSignalUseCase
    let advertisementParser: AdvertisementPacketParser
    let scanResponseParser: ScanResponseParser
    let candidateAssembler: VolnaCandidateAssembler
    let paymentSubmissionService: PaymentSubmissionServiceProtocol

    init(
        logger: AppLogger = AppLogger(),
        prerequisitesChecker: PrerequisitesCheckingPlaceholder = PrerequisitesCheckingPlaceholder(),
        scanner: BleScannerProtocol = CoreBluetoothBleScanner(),
        validateSignalUseCase: ValidateSignalUseCase = ValidateSignalUseCase(),
        advertisementParser: AdvertisementPacketParser = AdvertisementPacketParser(),
        scanResponseParser: ScanResponseParser = ScanResponseParser(),
        candidateAssembler: VolnaCandidateAssembler = VolnaCandidateAssembler(),
        paymentSubmissionService: PaymentSubmissionServiceProtocol = PlaceholderPaymentSubmissionService()
    ) {
        self.logger = logger
        self.prerequisitesChecker = prerequisitesChecker
        self.scanner = scanner
        self.validateSignalUseCase = validateSignalUseCase
        self.advertisementParser = advertisementParser
        self.scanResponseParser = scanResponseParser
        self.candidateAssembler = candidateAssembler
        self.paymentSubmissionService = paymentSubmissionService
    }
}
