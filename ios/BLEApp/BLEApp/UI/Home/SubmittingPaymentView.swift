import SwiftUI

struct SubmittingPaymentView: View {
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
