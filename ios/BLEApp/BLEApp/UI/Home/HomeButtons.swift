import SwiftUI

struct BluePrimaryButton: View {
    let title: String
    let action: () -> Void
    let isEnabled: Bool

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .frame(maxWidth: 330)
                .frame(height: 56)
                .foregroundStyle(HomePalette.white)
                .background(isEnabled ? HomePalette.brandOrange : HomePalette.brandOrange.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

struct BottomCTAContainer<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, 28)
            .padding(.top, 8)
            .padding(.bottom, 18)
            .background(Color.clear)
    }
}
