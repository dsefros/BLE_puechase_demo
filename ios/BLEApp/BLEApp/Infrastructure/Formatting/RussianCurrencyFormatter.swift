import Foundation

enum RussianCurrencyFormatter {
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

    static func formatAmount(_ amountMinor: UInt32) -> String {
        rubFormatter.string(from: NSNumber(value: Double(amountMinor) / 100.0)) ?? "0,00 ₽"
    }
}
