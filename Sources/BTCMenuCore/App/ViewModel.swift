import AppKit
import Foundation

@MainActor
final class BTCMenuViewModel {
    var onStateChange: ((BTCMenuState) -> Void)?

    var apiKey: String { preferences.apiKey }
    var alertConfig: AlertConfiguration { preferences.alertConfiguration }
    var priceSourcePreference: PriceSourcePreference { preferences.priceSourcePreference }
    var lastErrorDetails: ErrorDetails? { storedLastErrorDetails }
    var launchesAtLogin: Bool { launchAtLoginController.launchesAtLogin }

    private let preferences: AppPreferences
    private let client: BTCQuoteClient
    private let alertService: AlertServicing
    private let launchAtLoginController: LaunchAtLoginControlling

    private var currency: Currency
    private var lastPrice: Double?
    private var change24h: Double?
    private var lastFetchDate: Date?
    private var lastUpdateDescription = "Última atualização: --:--"
    private var change24hDescription = "Variação 24h: --"
    private var volumeDescription = "Volume 24h: --"
    private var lastErrorDescription: String?
    private var storedLastErrorDetails: ErrorDetails?
    private var statusTitle = "₿ --"
    private var priceMovement: PriceMovement = .unchanged
    private var isFetching = false

    init(
        preferences: AppPreferences = AppPreferences(),
        client: BTCQuoteClient = LiveBTCQuoteClient(),
        alertService: AlertServicing = AlertService(),
        launchAtLoginController: LaunchAtLoginControlling = LaunchAtLoginController()
    ) {
        self.preferences = preferences
        self.client = client
        self.alertService = alertService
        self.launchAtLoginController = launchAtLoginController
        self.currency = preferences.currency
    }

    func start() async {
        await updatePrice(force: true)
    }

    func emitState() {
        onStateChange?(makeState())
    }

    func setCurrency(_ currency: Currency) async {
        guard self.currency != currency else { return }
        self.currency = currency
        preferences.currency = currency
        emitState()
        await updatePrice(force: true)
    }

    func setAPIKey(_ apiKey: String) async {
        preferences.apiKey = apiKey
        emitState()
    }

    func setPriceSourcePreference(_ preference: PriceSourcePreference) {
        preferences.priceSourcePreference = preference
        emitState()
    }

    func setAlertConfig(_ config: AlertConfiguration) {
        preferences.alertConfiguration = config
        emitState()
    }

    func setLaunchAtLogin(_ isEnabled: Bool) {
        launchAtLoginController.setLaunchesAtLogin(isEnabled)
        emitState()
    }

    func playTestAlert() {
        alertService.beep()
        alertService.notify(title: "BTCMenu", message: "Teste de alerta executado")
    }

    func updatePrice(force: Bool) async {
        guard !isFetching else { return }
        if !force, let lastFetchDate, Date().timeIntervalSince(lastFetchDate) < 60 {
            return
        }
        isFetching = true
        if force {
            statusTitle = "₿ ..."
            emitState()
        }

        do {
            let quote = try await client.fetchBTCQuote(
                apiKey: apiKey.isEmpty ? nil : apiKey,
                currency: currency,
                preference: priceSourcePreference
            )
            apply(quote: quote)
        } catch {
            let details = Self.details(for: error)
            let debugDescription = details.message
            lastErrorDescription = debugDescription
            storedLastErrorDetails = details
            AppLogger.pricing.error("Price update failed: \(debugDescription, privacy: .public)")
            statusTitle = "₿ erro"
            emitState()
        }

        isFetching = false
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }

    private func apply(quote: BTCQuote) {
        let previousPrice = lastPrice
        lastPrice = quote.price
        change24h = quote.percentChange24h
        lastFetchDate = Date()

        let symbol = currency.symbol
        let movementSymbol: String
        if let previousPrice {
            if quote.price > previousPrice {
                priceMovement = .up
                movementSymbol = "↑"
            } else if quote.price < previousPrice {
                priceMovement = .down
                movementSymbol = "↓"
            } else {
                priceMovement = .unchanged
                movementSymbol = "→"
            }
        } else {
            priceMovement = .unchanged
            movementSymbol = "→"
        }

        statusTitle = "\(movementSymbol) ₿ \(symbol)\(Formatting.compactPrice(quote.price))"
        change24hDescription = "Variação 24h: \(Formatting.change(quote.percentChange24h))"
        volumeDescription = "Volume 24h: \(symbol)\(Formatting.volume(quote.volume24h))"
        lastUpdateDescription = "Última atualização: \(Formatting.time(Date()))"
        lastErrorDescription = nil
        storedLastErrorDetails = nil

        emitState()
        checkAlerts(quote: quote, previousPrice: previousPrice)
    }

    private func checkAlerts(quote: BTCQuote, previousPrice: Double?) {
        let config = preferences.alertConfiguration
        guard config.enabled else { return }

        switch config.type {
        case .price:
            guard
                let target = config.priceTarget,
                target > 0,
                let previousPrice
            else { return }

            let crossedUp = previousPrice < target && quote.price >= target
            let crossedDown = previousPrice > target && quote.price <= target
            let triggered = (config.priceDirection == .above && crossedUp) || (config.priceDirection == .below && crossedDown)
            guard triggered else { return }

            let arrow = config.priceDirection == .above ? "↑" : "↓"
            alertService.notify(
                title: "BTCMenu",
                message: "Alerta de preço \(arrow): \(String(format: "%.2f", quote.price)) \(currency.rawValue.uppercased())"
            )
            alertService.beep()

            if !config.priceRepeat {
                var disabledConfig = config
                disabledConfig.enabled = false
                preferences.alertConfiguration = disabledConfig
                emitState()
            }

        case .variation:
            let currentVariation: Double?
            switch config.variationWindow {
            case .oneHour:
                currentVariation = quote.percentChange1h
            case .threeHours:
                currentVariation = quote.percentChange3h
            case .twentyFourHours:
                currentVariation = quote.percentChange24h
            }

            guard let currentVariation, abs(currentVariation) >= config.variationThreshold else { return }

            let direction = currentVariation >= 0 ? "↑" : "↓"
            alertService.notify(
                title: "BTCMenu",
                message: "Variação \(config.variationWindow.rawValue) \(direction) \(String(format: "%.2f", currentVariation))% (limite \(String(format: "%.1f", config.variationThreshold))%)"
            )
            alertService.beep()

            var disabledConfig = config
            disabledConfig.enabled = false
            preferences.alertConfiguration = disabledConfig
            emitState()
        }
    }

    private func makeState() -> BTCMenuState {
        BTCMenuState(
            statusTitle: statusTitle,
            priceMovement: priceMovement,
            currency: currency,
            launchesAtLogin: launchAtLoginController.launchesAtLogin,
            lastUpdateDescription: lastUpdateDescription,
            change24hDescription: change24hDescription,
            volumeDescription: volumeDescription,
            priceSourceDescription: "Fonte de preco: \(priceSourcePreference.title)",
            lastErrorDescription: lastErrorDescription,
            hasErrorDetails: storedLastErrorDetails != nil,
            apiKeyConfigured: !apiKey.isEmpty,
            alertEnabled: alertConfig.enabled
        )
    }

    private static func details(for error: Error) -> ErrorDetails {
        if let apiError = error as? APIError {
            return ErrorDetails(
                title: "Falha ao atualizar preco",
                message: apiError.summary,
                responseBody: apiError.responseBody,
                timestamp: Date()
            )
        }

        if let urlError = error as? URLError {
            return ErrorDetails(
                title: "Erro de rede",
                message: "Erro de rede: \(urlError.localizedDescription)",
                responseBody: nil,
                timestamp: Date()
            )
        }

        return ErrorDetails(
            title: "Erro inesperado",
            message: String(describing: error),
            responseBody: nil,
            timestamp: Date()
        )
    }
}
