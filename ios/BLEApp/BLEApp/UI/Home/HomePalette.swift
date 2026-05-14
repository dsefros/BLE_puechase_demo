import SwiftUI

enum HomePalette {
    static let brandOrange = Color(hex: 0x176FC6)
    static let brandBlack = Color(hex: 0x000000)
    static let brandGray = Color(hex: 0xD7E6EA)
    static let brandDarkGray = Color(hex: 0x2C2C2C)
    static let brandGreen = Color(hex: 0x27B648)
    static let brandRed = Color(hex: 0xEA002F)
    static let white = Color(hex: 0xFFFFFF)
    static let overlay = Color(red: 235 / 255, green: 235 / 255, blue: 235 / 255, opacity: 0.50)
    static let brandLightGray = Color(hex: 0xE9F1F3)
    static let settingsCard = Color(hex: 0xF5F5F5)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }
}
