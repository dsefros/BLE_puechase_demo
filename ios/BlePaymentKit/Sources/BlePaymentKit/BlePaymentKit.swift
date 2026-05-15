import Foundation

public final class BlePaymentKit {
    private let config: BlePaymentConfig
    private let decoder: BlePayloadDecoder
    private let signalValidator: SignalValidator
    private let candidateValidator: PaymentCandidateValidator

    public init(config: BlePaymentConfig = .default) {
        self.config = config
        self.decoder = BlePayloadDecoder()
        self.signalValidator = SignalValidator()
        self.candidateValidator = PaymentCandidateValidator()
    }

    public func process(input: BlePacketInput) -> BlePacketProcessingResult {
        switch decoder.decode(input: input, config: config) {
        case .failure(let reason):
            return .rejected(reason)
        case .success(let decoded):
            let advertisement = decoded.0
            let scanResponse = decoded.1
            if case .invalid(let reason) = signalValidator.validate(rssi: input.rssi, rssiDelta: advertisement.rssiDelta, config: config) {
                return .rejected(reason)
            }
            let finalRssi = signalValidator.finalRssi(rssi: input.rssi, rssiDelta: advertisement.rssiDelta)
            return .accepted(BlePaymentCandidate(qrcId: advertisement.qrcId, qrLink: candidateValidator.qrLink(qrcId: advertisement.qrcId, config: config), amountMinor: scanResponse.amountMinor, merchantName: scanResponse.merchantName, packetVersion: advertisement.packetVersion, operationCounter: advertisement.operationCounter, rssi: input.rssi, finalRssi: finalRssi, rssiDelta: advertisement.rssiDelta, deviceIdentifier: input.deviceIdentifier, localName: input.localName, timestamp: input.timestamp))
        }
    }
}
