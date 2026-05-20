import SwiftUI

struct CandidateConfirmationView: View {
    let candidate: PaymentCandidate
    let formatAmount: (UInt32) -> String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    let isEnabled: Bool

    var body: some View {
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
            .padding(.horizontal, 28)
            .padding(.top, 18)
            .padding(.bottom, 12)

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 24)

                    VStack(spacing: 0) {
                        ZStack {
                            LottieView(
                                animationName: "store_animated",
                                loopMode: .loop,
                                contentMode: .aspectFit,
                                autoplay: true,
                                scale: 1.0,
                                fallback: { BluetoothHeroIcon() }
                            )
                            .frame(width: 200, height: 200)
                            .scaleEffect(0.37)
                        }
                        .frame(width: 200, height: 200)
                        .padding(.bottom, 24)

                        ConfirmationSection(
                            label: "Магазин",
                            value: candidate.merchant.isEmpty ? "—" : candidate.merchant
                        )

                        Spacer().frame(height: 12)
                        Divider().background(HomePalette.brandLightGray)
                        Spacer().frame(height: 12)

                        ConfirmationSection(
                            label: "Сумма к оплате",
                            value: formatAmount(candidate.amountMinor),
                            isAmount: true
                        )
                    }
                    .padding(32)
                    .frame(maxWidth: .infinity)
                    .background(HomePalette.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 8)
                    .padding(.bottom, 16)

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 18)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            BottomCTAContainer {
                BluePrimaryButton(
                    title: "Оплатить \(formatAmount(candidate.amountMinor))",
                    action: onConfirm,
                    isEnabled: isEnabled
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ConfirmationSection: View {
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
