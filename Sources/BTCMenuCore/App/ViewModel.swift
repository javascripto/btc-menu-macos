import AppKit
import Foundation

@MainActor
final class BTCMenuViewModel {
    var onStateChange: ((BTCMenuState) -> Void)?

    var apiKey: String { preferences.apiKey }
    var alertConfig: AlertConfiguration { preferences.alertConfiguration }
    var displayOptions: DisplayOptions { currentDisplayOptions }
    var priceSourcePreference: PriceSourcePreference { preferences.priceSourcePreference }
    var lastErrorDetails: ErrorDetails? { storedLastErrorDetails }
    var launchesAtLogin: Bool { launchAtLoginController.launchesAtLogin }

    private let preferences: AppPreferences
    private let client: BTCQuoteClient
    private let alertService: AlertServicing
    private let launchAtLoginController: LaunchAtLoginControlling

    private var currentDisplayOptions: DisplayOptions
    private var priceHistory: [PriceSample]
    private var latestSnapshot: QuoteSnapshot?
    private var previousBTCUSD: Double?
    private var previousBTCBRL: Double?
    private var previousUSDBRL: Double?
    private var lastFetchDate: Date?
    private var lastUpdateDescription = "Última atualização: --:--"
    private var change1hDescription = "Variação 1h: --"
    private var change24hDescription = "Variação 24h: --"
    private var change7dDescription = "Variação 7d: --"
    private var change30dDescription = "Variação 30d: --"
    private var volumeDescription = "Volume 24h: --"
    private var lastErrorDescription: String?
    private var storedLastErrorDetails: ErrorDetails?
    private var statusTitle = "--"
    private var quoteMovements = QuoteMovements(btcUSD: .unchanged, btcBRL: .unchanged, usdBRL: .unchanged)
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
        self.currentDisplayOptions = preferences.displayOptions
        self.priceHistory = preferences.priceHistory
    }

    func start() async {
        await updatePrice(force: true)
    }

    func emitState() {
        onStateChange?(makeState())
    }

    func setDisplayOptions(_ displayOptions: DisplayOptions) async {
        guard currentDisplayOptions != displayOptions else { return }
        currentDisplayOptions = displayOptions
        preferences.displayOptions = displayOptions
        rebuildStatusTitle()
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
            statusTitle = latestSnapshot == nil ? "--" : statusTitle
            emitState()
        }

        do {
            let quote = try await client.fetchQuoteSnapshot(
                apiKey: apiKey.isEmpty ? nil : apiKey,
                preference: priceSourcePreference
            )
            apply(quote: quote)
        } catch {
            let details = Self.details(for: error)
            let debugDescription = details.message
            lastErrorDescription = debugDescription
            storedLastErrorDetails = details
            AppLogger.pricing.error("Price update failed: \(debugDescription, privacy: .public)")
            rebuildStatusTitle()
            emitState()
        }

        isFetching = false
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }

    private func apply(quote: QuoteSnapshot) {
        let previousPrice = latestSnapshot?.primaryBTCQuote().price
        latestSnapshot = quote
        lastFetchDate = Date()
        quoteMovements = QuoteMovements(
            btcUSD: Self.movement(for: quote.btcUSD, previous: previousBTCUSD),
            btcBRL: Self.movement(for: quote.btcBRL, previous: previousBTCBRL),
            usdBRL: Self.movement(for: quote.usdBRL, previous: previousUSDBRL, roundedTo: 2)
        )
        previousBTCUSD = quote.btcUSD
        previousBTCBRL = quote.btcBRL
        previousUSDBRL = quote.usdBRL
        appendPriceSample(price: quote.btcBRL, at: Date())

        let primaryQuote = quote.primaryBTCQuote()
        statusTitle = StatusTitleBuilder.build(snapshot: quote, options: currentDisplayOptions, movements: quoteMovements)
        change1hDescription = "Variação 1h: \(Formatting.change(primaryQuote.percentChange1h))"
        change24hDescription = "Variação 24h: \(Formatting.change(primaryQuote.percentChange24h))"
        change7dDescription = "Variação 7d: \(Formatting.change(primaryQuote.percentChange7d))"
        change30dDescription = "Variação 30d: \(Formatting.change(primaryQuote.percentChange30d))"
        volumeDescription = "Volume 24h: $\(Formatting.volume(quote.btcUSDVolume24h))"
        lastUpdateDescription = "Última atualização: \(Formatting.time(Date()))"
        lastErrorDescription = nil
        storedLastErrorDetails = nil

        emitState()
        checkAlerts(quote: primaryQuote, previousPrice: previousPrice)
    }

    private func checkAlerts(quote: PrimaryBTCQuote, previousPrice: Double?) {
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
            AppLogger.alerts.info(
                "Price alert triggered: direction=\(config.priceDirection.rawValue, privacy: .public) current=\(quote.price, privacy: .public) target=\(target, privacy: .public) currency=\(quote.currency.rawValue, privacy: .public)"
            )
            alertService.notify(
                title: "BTCMenu",
                message: "Alerta de preço \(arrow): \(String(format: "%.2f", quote.price)) \(quote.currency.rawValue.uppercased())"
            )
            alertService.beep()

            if !config.priceRepeat {
                var disabledConfig = config
                disabledConfig.enabled = false
                preferences.alertConfiguration = disabledConfig
                emitState()
            }

        case .variation:
            let currentVariation = variationOverWindow(config.variationWindow, currentPrice: quote.price)

            guard let currentVariation, abs(currentVariation) >= config.variationThreshold else { return }

            let direction = currentVariation >= 0 ? "↑" : "↓"
            AppLogger.alerts.info(
                "Variation alert triggered: window=\(config.variationWindow.rawValue, privacy: .public) current=\(currentVariation, privacy: .public) threshold=\(config.variationThreshold, privacy: .public)"
            )
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
            quoteMovements: quoteMovements,
            displayOptions: currentDisplayOptions,
            launchesAtLogin: launchAtLoginController.launchesAtLogin,
            lastUpdateDescription: lastUpdateDescription,
            change1hDescription: change1hDescription,
            change24hDescription: change24hDescription,
            change7dDescription: change7dDescription,
            change30dDescription: change30dDescription,
            volumeDescription: volumeDescription,
            priceSourceDescription: "Fonte de preco: \(priceSourcePreference.title)",
            lastErrorDescription: lastErrorDescription,
            hasErrorDetails: storedLastErrorDetails != nil,
            apiKeyConfigured: !apiKey.isEmpty,
            alertEnabled: alertConfig.enabled
        )
    }

    private func rebuildStatusTitle() {
        statusTitle = StatusTitleBuilder.build(snapshot: latestSnapshot, options: currentDisplayOptions, movements: quoteMovements)
    }

    private static func movement(for value: Double, previous: Double?, roundedTo decimalPlaces: Int? = nil) -> PriceMovement {
        guard let previous else { return .unchanged }
        let currentValue: Double
        let previousValue: Double

        if let decimalPlaces {
            let factor = pow(10.0, Double(decimalPlaces))
            currentValue = (value * factor).rounded() / factor
            previousValue = (previous * factor).rounded() / factor
        } else {
            currentValue = value
            previousValue = previous
        }

        if currentValue > previousValue { return .up }
        if currentValue < previousValue { return .down }
        return .unchanged
    }

    private func appendPriceSample(price: Double, at timestamp: Date) {
        priceHistory.append(PriceSample(timestamp: timestamp, btcBRL: price))
        let oldestAllowed = timestamp.addingTimeInterval(-(2 * 60 * 60))
        priceHistory.removeAll { $0.timestamp < oldestAllowed }
        preferences.priceHistory = priceHistory
    }

    private func variationOverWindow(_ window: AlertVariationWindow, currentPrice: Double) -> Double? {
        let cutoff = Date().addingTimeInterval(-window.interval)
        guard let sample = priceHistory.last(where: { $0.timestamp <= cutoff }) else { return nil }
        guard sample.btcBRL > 0 else { return nil }
        return ((currentPrice - sample.btcBRL) / sample.btcBRL) * 100
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
