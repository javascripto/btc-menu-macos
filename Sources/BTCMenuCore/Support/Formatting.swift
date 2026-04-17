import Foundation

enum Formatting {
    private static let locale = Locale(identifier: "pt_BR")

    static func price(_ value: Double) -> String {
        decimalString(value, fractionDigits: 2)
    }

    static func compactPrice(_ value: Double) -> String {
        decimalString(value, fractionDigits: 0)
    }

    static func volume(_ value: Double) -> String {
        decimalString(value, fractionDigits: 0)
    }

    static func exchangeRate(_ value: Double) -> String {
        decimalString(value, fractionDigits: 2)
    }

    static func change(_ value: Double?) -> String {
        guard let value else { return "--" }
        let indicator = value > 0 ? "↑" : value < 0 ? "↓" : "→"
        return "\(indicator) \(String(format: "%.2f", value))%"
    }

    static func time(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    private static func decimalString(_ value: Double, fractionDigits: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
}
