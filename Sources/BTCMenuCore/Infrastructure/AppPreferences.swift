import Foundation

enum Currency: String, CaseIterable {
    case usd
    case brl

    var symbol: String {
        switch self {
        case .usd:
            return "$"
        case .brl:
            return "R$"
        }
    }
}

enum PriceSourcePreference: String, CaseIterable {
    case publicAPI = "public_api"
    case coinMarketCap = "coinmarketcap"

    var title: String {
        switch self {
        case .publicAPI:
            return "CoinGecko (API publica)"
        case .coinMarketCap:
            return "CoinMarketCap"
        }
    }
}

enum AlertType: String {
    case price
    case variation
}

enum PriceDirection: String {
    case above
    case below
}

enum VariationWindow: String, CaseIterable {
    case oneHour = "1h"
    case twentyFourHours = "24h"
    case sevenDays = "7d"
    case thirtyDays = "30d"
}

struct AlertConfiguration {
    var enabled: Bool
    var type: AlertType
    var priceDirection: PriceDirection
    var priceTarget: Double?
    var priceRepeat: Bool
    var variationWindow: VariationWindow
    var variationThreshold: Double

    static let `default` = AlertConfiguration(
        enabled: false,
        type: .price,
        priceDirection: .above,
        priceTarget: nil,
        priceRepeat: true,
        variationWindow: .twentyFourHours,
        variationThreshold: 1.0
    )
}

@MainActor
final class AppPreferences {
    private enum Keys {
        static let currency = "currency"
        static let apiKey = "api_key"
        static let priceSourcePreference = "price_source_preference"
        static let showDollarRate = "show_dollar_rate"
        static let showBitcoinUSD = "show_bitcoin_usd"
        static let showBitcoinBRL = "show_bitcoin_brl"
        static let showBitcoinCents = "show_bitcoin_cents"
        static let alertEnabled = "alert_enabled"
        static let alertType = "alert_type"
        static let alertPriceDirection = "alert_price_direction"
        static let alertPriceTarget = "alert_price_target"
        static let alertPriceRepeat = "alert_price_repeat"
        static let alertVariationWindow = "alert_variation_window"
        static let alertVariationThreshold = "alert_variation_threshold"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var currency: Currency {
        get {
            Currency(rawValue: userDefaults.string(forKey: Keys.currency) ?? "") ?? .usd
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Keys.currency)
        }
    }

    var displayOptions: DisplayOptions {
        get {
            let hasDisplayKeys =
                userDefaults.object(forKey: Keys.showDollarRate) != nil ||
                userDefaults.object(forKey: Keys.showBitcoinUSD) != nil ||
                userDefaults.object(forKey: Keys.showBitcoinBRL) != nil

            guard hasDisplayKeys else {
                if currency == .brl {
                    return DisplayOptions(showDollarRate: false, showBitcoinUSD: false, showBitcoinBRL: true, showBitcoinCents: false)
                }

                return .default
            }

            return DisplayOptions(
                showDollarRate: userDefaults.bool(forKey: Keys.showDollarRate),
                showBitcoinUSD: userDefaults.bool(forKey: Keys.showBitcoinUSD),
                showBitcoinBRL: userDefaults.bool(forKey: Keys.showBitcoinBRL),
                showBitcoinCents: userDefaults.bool(forKey: Keys.showBitcoinCents)
            )
        }
        set {
            userDefaults.set(newValue.showDollarRate, forKey: Keys.showDollarRate)
            userDefaults.set(newValue.showBitcoinUSD, forKey: Keys.showBitcoinUSD)
            userDefaults.set(newValue.showBitcoinBRL, forKey: Keys.showBitcoinBRL)
            userDefaults.set(newValue.showBitcoinCents, forKey: Keys.showBitcoinCents)
        }
    }

    var apiKey: String {
        get { userDefaults.string(forKey: Keys.apiKey) ?? "" }
        set { userDefaults.set(newValue, forKey: Keys.apiKey) }
    }

    var priceSourcePreference: PriceSourcePreference {
        get {
            PriceSourcePreference(rawValue: userDefaults.string(forKey: Keys.priceSourcePreference) ?? "") ?? .publicAPI
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Keys.priceSourcePreference)
        }
    }

    var alertConfiguration: AlertConfiguration {
        get {
            AlertConfiguration(
                enabled: userDefaults.object(forKey: Keys.alertEnabled) == nil ? false : userDefaults.bool(forKey: Keys.alertEnabled),
                type: AlertType(rawValue: userDefaults.string(forKey: Keys.alertType) ?? "") ?? .price,
                priceDirection: PriceDirection(rawValue: userDefaults.string(forKey: Keys.alertPriceDirection) ?? "") ?? .above,
                priceTarget: userDefaults.object(forKey: Keys.alertPriceTarget).flatMap { Double("\($0)") },
                priceRepeat: userDefaults.object(forKey: Keys.alertPriceRepeat) == nil ? true : userDefaults.bool(forKey: Keys.alertPriceRepeat),
                variationWindow: VariationWindow(rawValue: userDefaults.string(forKey: Keys.alertVariationWindow) ?? "") ?? .twentyFourHours,
                variationThreshold: userDefaults.object(forKey: Keys.alertVariationThreshold).flatMap { Double("\($0)") } ?? 1.0
            )
        }
        set {
            userDefaults.set(newValue.enabled, forKey: Keys.alertEnabled)
            userDefaults.set(newValue.type.rawValue, forKey: Keys.alertType)
            userDefaults.set(newValue.priceDirection.rawValue, forKey: Keys.alertPriceDirection)
            if let priceTarget = newValue.priceTarget {
                userDefaults.set(priceTarget, forKey: Keys.alertPriceTarget)
            } else {
                userDefaults.removeObject(forKey: Keys.alertPriceTarget)
            }
            userDefaults.set(newValue.priceRepeat, forKey: Keys.alertPriceRepeat)
            userDefaults.set(newValue.variationWindow.rawValue, forKey: Keys.alertVariationWindow)
            userDefaults.set(newValue.variationThreshold, forKey: Keys.alertVariationThreshold)
        }
    }
}
