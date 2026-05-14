import SwiftUI

struct AndroidCenterLayout<Visual: View>: View {
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
