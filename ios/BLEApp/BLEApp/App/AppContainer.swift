import Foundation

struct AppContainer {
    let logger: AppLogger
    let prerequisitesChecker: PrerequisitesCheckingPlaceholder
    let scanner: BleScannerProtocol
    let validateSignalUseCase: ValidateSignalUseCase
    let advertisementParser: AdvertisementPacketParserPlaceholder
    let scanResponseParser: ScanResponseParserPlaceholder

    init(
        logger: AppLogger = AppLogger(),
        prerequisitesChecker: PrerequisitesCheckingPlaceholder = PrerequisitesCheckingPlaceholder(),
        scanner: BleScannerProtocol = BleScannerPlaceholder(),
        validateSignalUseCase: ValidateSignalUseCase = ValidateSignalUseCase(),
        advertisementParser: AdvertisementPacketParserPlaceholder = AdvertisementPacketParserPlaceholder(),
        scanResponseParser: ScanResponseParserPlaceholder = ScanResponseParserPlaceholder()
    ) {
        self.logger = logger
        self.prerequisitesChecker = prerequisitesChecker
        self.scanner = scanner
        self.validateSignalUseCase = validateSignalUseCase
        self.advertisementParser = advertisementParser
        self.scanResponseParser = scanResponseParser
    }
}
