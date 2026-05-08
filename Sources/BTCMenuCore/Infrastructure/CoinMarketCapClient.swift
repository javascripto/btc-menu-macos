import Foundation

private struct CurrencyQuote: Decodable {
    let price: Double
    let volume24h: Double
    let percentChange1h: Double?
    let percentChange24h: Double?
    let percentChange7d: Double?
    let percentChange30d: Double?

    private enum CodingKeys: String, CodingKey {
        case price
        case volume24h = "volume_24h"
        case percentChange1h = "percent_change_1h"
        case percentChange24h = "percent_change_24h"
        case percentChange7d = "percent_change_7d"
        case percentChange30d = "percent_change_30d"
    }
}

protocol BTCQuoteClient: Sendable {
    func fetchQuoteSnapshot(
        apiKey: String?,
        preference: PriceSourcePreference
    ) async throws -> QuoteSnapshot
}

struct LiveBTCQuoteClient: BTCQuoteClient, Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchQuoteSnapshot(
        apiKey: String?,
        preference: PriceSourcePreference
    ) async throws -> QuoteSnapshot {
        if preference == .coinMarketCap, let apiKey, !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            AppLogger.pricing.info("Request start: source=coinmarketcap currencies=usd,brl")
            do {
                let quote = try await fetchCoinMarketCapQuote(apiKey: apiKey)
                AppLogger.pricing.info(
                    "Request success: source=coinmarketcap btcUSD=\(quote.btcUSD, privacy: .public) btcBRL=\(quote.btcBRL, privacy: .public) ethUSD=\(quote.ethUSD, privacy: .public) ethBRL=\(quote.ethBRL, privacy: .public)"
                )
                return quote
            } catch let error as APIError where error.shouldFallbackToCoinGecko {
                AppLogger.pricing.warning(
                    "Request fallback: source=coinmarketcap currencies=usd,brl reason=\(error.debugDescription, privacy: .public)"
                )
                AppLogger.pricing.info("Request start: source=coingecko currencies=usd,brl")
                let quote = try await fetchCoinGeckoQuote()
                AppLogger.pricing.info(
                    "Request success: source=coingecko btcUSD=\(quote.btcUSD, privacy: .public) btcBRL=\(quote.btcBRL, privacy: .public) ethUSD=\(quote.ethUSD, privacy: .public) ethBRL=\(quote.ethBRL, privacy: .public)"
                )
                return quote
            } catch {
                AppLogger.pricing.error(
                    "Request failure: source=coinmarketcap currencies=usd,brl error=\(String(describing: error), privacy: .public)"
                )
                throw error
            }
        }

        if preference == .coinMarketCap {
            AppLogger.pricing.warning(
                "Request fallback: source=coinmarketcap currencies=usd,brl reason=no_api_key_configured"
            )
        }

        AppLogger.pricing.info("Request start: source=coingecko currencies=usd,brl")
        do {
            let quote = try await fetchCoinGeckoQuote()
            AppLogger.pricing.info(
                "Request success: source=coingecko btcUSD=\(quote.btcUSD, privacy: .public) btcBRL=\(quote.btcBRL, privacy: .public) ethUSD=\(quote.ethUSD, privacy: .public) ethBRL=\(quote.ethBRL, privacy: .public)"
            )
            return quote
        } catch {
            AppLogger.pricing.error(
                "Request failure: source=coingecko currencies=usd,brl error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    private func fetchCoinMarketCapQuote(apiKey: String) async throws -> QuoteSnapshot {
        var components = URLComponents(string: "https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest")
        components?.queryItems = [
            URLQueryItem(name: "symbol", value: "BTC,ETH"),
            URLQueryItem(name: "convert", value: "USD,BRL"),
        ]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        AppLogger.pricing.debug("HTTP request: source=coinmarketcap url=\(url.absoluteString, privacy: .public)")

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.setValue("application/json", forHTTPHeaderField: "Accepts")
        request.setValue(apiKey, forHTTPHeaderField: "X-CMC_PRO_API_KEY")
        request.setValue("BTCMenu/1.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        if let httpResponse = response as? HTTPURLResponse {
            AppLogger.pricing.debug(
                "HTTP response: source=coinmarketcap status=\(httpResponse.statusCode, privacy: .public)"
            )
        }
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode
            throw APIError.invalidResponse(statusCode: statusCode, body: data.debugSnippet())
        }

        let decoded = try JSONDecoder().decode(CoinMarketCapResponse.self, from: data)
        guard
            let quoteUSD = decoded.data["BTC"]?.quote["USD"],
            let quoteBRL = decoded.data["BTC"]?.quote["BRL"]
        else {
            throw APIError.missingQuote
        }

        var ethUSD: Double = 0
        var ethBRL: Double = 0
        var ethUSDVolume24h: Double = 0
        var ethBRLVolume24h: Double = 0
        var ethUSDPercentChange1h: Double? = nil
        var ethBRLPercentChange1h: Double? = nil
        var ethUSDPercentChange24h: Double? = nil
        var ethBRLPercentChange24h: Double? = nil
        var ethUSDPercentChange7d: Double? = nil
        var ethBRLPercentChange7d: Double? = nil
        var ethUSDPercentChange30d: Double? = nil
        var ethBRLPercentChange30d: Double? = nil

        if let ethQuoteUSD = decoded.data["ETH"]?.quote["USD"],
           let ethQuoteBRL = decoded.data["ETH"]?.quote["BRL"] {
            ethUSD = ethQuoteUSD.price
            ethBRL = ethQuoteBRL.price
            ethUSDVolume24h = ethQuoteUSD.volume24h
            ethBRLVolume24h = ethQuoteBRL.volume24h
            ethUSDPercentChange1h = ethQuoteUSD.percentChange1h
            ethBRLPercentChange1h = ethQuoteBRL.percentChange1h
            ethUSDPercentChange24h = ethQuoteUSD.percentChange24h
            ethBRLPercentChange24h = ethQuoteBRL.percentChange24h
            ethUSDPercentChange7d = ethQuoteUSD.percentChange7d
            ethBRLPercentChange7d = ethQuoteBRL.percentChange7d
            ethUSDPercentChange30d = ethQuoteUSD.percentChange30d
            ethBRLPercentChange30d = ethQuoteBRL.percentChange30d
        } else {
            AppLogger.pricing.warning("Ethereum quote not found in CoinMarketCap response")
        }

        return QuoteSnapshot(
            btcUSD: quoteUSD.price,
            btcBRL: quoteBRL.price,
            ethUSD: ethUSD,
            ethBRL: ethBRL,
            usdBRL: quoteBRL.price / quoteUSD.price,
            btcUSDVolume24h: quoteUSD.volume24h,
            btcBRLVolume24h: quoteBRL.volume24h,
            ethUSDVolume24h: ethUSDVolume24h,
            ethBRLVolume24h: ethBRLVolume24h,
            btcUSDPercentChange1h: quoteUSD.percentChange1h,
            btcBRLPercentChange1h: quoteBRL.percentChange1h,
            ethUSDPercentChange1h: ethUSDPercentChange1h,
            ethBRLPercentChange1h: ethBRLPercentChange1h,
            btcUSDPercentChange24h: quoteUSD.percentChange24h,
            btcBRLPercentChange24h: quoteBRL.percentChange24h,
            ethUSDPercentChange24h: ethUSDPercentChange24h,
            ethBRLPercentChange24h: ethBRLPercentChange24h,
            btcUSDPercentChange7d: quoteUSD.percentChange7d,
            btcBRLPercentChange7d: quoteBRL.percentChange7d,
            ethUSDPercentChange7d: ethUSDPercentChange7d,
            ethBRLPercentChange7d: ethBRLPercentChange7d,
            btcUSDPercentChange30d: quoteUSD.percentChange30d,
            btcBRLPercentChange30d: quoteBRL.percentChange30d,
            ethUSDPercentChange30d: ethUSDPercentChange30d,
            ethBRLPercentChange30d: ethBRLPercentChange30d
        )
    }

    private func fetchCoinGeckoQuote() async throws -> QuoteSnapshot {
        async let bitcoinRequest = fetchCoinGeckoCryptoPrices(cryptoId: "bitcoin")
        async let ethereumRequest = fetchCoinGeckoCryptoPrices(cryptoId: "ethereum")

        let bitcoinData = try await bitcoinRequest
        let ethereumData = try await ethereumRequest

        let btcUSD = try value(for: bitcoinData.currentPrice, currency: .usd)
        let btcBRL = try value(for: bitcoinData.currentPrice, currency: .brl)
        let btcUSDVolume24h = try value(for: bitcoinData.totalVolume, currency: .usd)
        let btcBRLVolume24h = try value(for: bitcoinData.totalVolume, currency: .brl)

        let ethUSD = try value(for: ethereumData.currentPrice, currency: .usd)
        let ethBRL = try value(for: ethereumData.currentPrice, currency: .brl)
        let ethUSDVolume24h = try value(for: ethereumData.totalVolume, currency: .usd)
        let ethBRLVolume24h = try value(for: ethereumData.totalVolume, currency: .brl)

        return QuoteSnapshot(
            btcUSD: btcUSD,
            btcBRL: btcBRL,
            ethUSD: ethUSD,
            ethBRL: ethBRL,
            usdBRL: btcBRL / btcUSD,
            btcUSDVolume24h: btcUSDVolume24h,
            btcBRLVolume24h: btcBRLVolume24h,
            ethUSDVolume24h: ethUSDVolume24h,
            ethBRLVolume24h: ethBRLVolume24h,
            btcUSDPercentChange1h: try? bitcoinData.priceChangePercentage1hInCurrency.flatMap { try value(for: $0, currency: .usd) },
            btcBRLPercentChange1h: try? bitcoinData.priceChangePercentage1hInCurrency.flatMap { try value(for: $0, currency: .brl) },
            ethUSDPercentChange1h: try? ethereumData.priceChangePercentage1hInCurrency.flatMap { try value(for: $0, currency: .usd) },
            ethBRLPercentChange1h: try? ethereumData.priceChangePercentage1hInCurrency.flatMap { try value(for: $0, currency: .brl) },
            btcUSDPercentChange24h: try? bitcoinData.priceChangePercentage24hInCurrency.flatMap { try value(for: $0, currency: .usd) },
            btcBRLPercentChange24h: try? bitcoinData.priceChangePercentage24hInCurrency.flatMap { try value(for: $0, currency: .brl) },
            ethUSDPercentChange24h: try? ethereumData.priceChangePercentage24hInCurrency.flatMap { try value(for: $0, currency: .usd) },
            ethBRLPercentChange24h: try? ethereumData.priceChangePercentage24hInCurrency.flatMap { try value(for: $0, currency: .brl) },
            btcUSDPercentChange7d: try? bitcoinData.priceChangePercentage7dInCurrency.flatMap { try value(for: $0, currency: .usd) },
            btcBRLPercentChange7d: try? bitcoinData.priceChangePercentage7dInCurrency.flatMap { try value(for: $0, currency: .brl) },
            ethUSDPercentChange7d: try? ethereumData.priceChangePercentage7dInCurrency.flatMap { try value(for: $0, currency: .usd) },
            ethBRLPercentChange7d: try? ethereumData.priceChangePercentage7dInCurrency.flatMap { try value(for: $0, currency: .brl) },
            btcUSDPercentChange30d: try? bitcoinData.priceChangePercentage30dInCurrency.flatMap { try value(for: $0, currency: .usd) },
            btcBRLPercentChange30d: try? bitcoinData.priceChangePercentage30dInCurrency.flatMap { try value(for: $0, currency: .brl) },
            ethUSDPercentChange30d: try? ethereumData.priceChangePercentage30dInCurrency.flatMap { try value(for: $0, currency: .usd) },
            ethBRLPercentChange30d: try? ethereumData.priceChangePercentage30dInCurrency.flatMap { try value(for: $0, currency: .brl) }
        )
    }

    private func fetchCoinGeckoCryptoPrices(cryptoId: String) async throws -> CoinGeckoMarketData {
        var components = URLComponents(string: "https://api.coingecko.com/api/v3/coins/\(cryptoId)")
        components?.queryItems = [
            URLQueryItem(name: "localization", value: "false"),
            URLQueryItem(name: "tickers", value: "false"),
            URLQueryItem(name: "community_data", value: "false"),
            URLQueryItem(name: "developer_data", value: "false"),
            URLQueryItem(name: "sparkline", value: "false"),
        ]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        AppLogger.pricing.debug("HTTP request: source=coingecko url=\(url.absoluteString, privacy: .public)")

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("BTCMenu/1.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        if let httpResponse = response as? HTTPURLResponse {
            AppLogger.pricing.debug(
                "HTTP response: source=coingecko status=\(httpResponse.statusCode, privacy: .public)"
            )
        }
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode
            throw APIError.invalidResponse(statusCode: statusCode, body: data.debugSnippet())
        }

        let decoded = try JSONDecoder().decode(CoinGeckoResponse.self, from: data)
        return decoded.marketData
    }

    private func value(for dictionary: [String: Double], currency: Currency) throws -> Double {
        guard let value = dictionary[currency.rawValue.lowercased()] else {
            throw APIError.missingQuote
        }

        return value
    }
}

enum APIError: Error {
    case invalidResponse(statusCode: Int?, body: String?)
    case missingQuote
}

extension APIError: CustomStringConvertible, CustomDebugStringConvertible {
    var description: String {
        debugDescription
    }

    var debugDescription: String {
        switch self {
        case let .invalidResponse(statusCode, body):
            let statusPart = statusCode.map { "status \($0)" } ?? "status desconhecido"
            let bodyPart: String
            if let body, !body.isEmpty {
                bodyPart = " | corpo: \(body)"
            } else {
                bodyPart = ""
            }
            return "Resposta inválida da API (\(statusPart))\(bodyPart)"
        case .missingQuote:
            return "Cotação BTC/ETH não encontrada na resposta da API"
        }
    }
}

extension APIError {
    var isRateLimited: Bool {
        if case let .invalidResponse(statusCode, _) = self {
            return statusCode == 429
        }

        return false
    }

    var summary: String {
        debugDescription
    }

    var responseBody: String? {
        if case let .invalidResponse(_, body) = self {
            return body
        }

        return nil
    }

    var shouldFallbackToCoinGecko: Bool {
        if isRateLimited {
            return true
        }

        if case let .invalidResponse(_, body) = self,
           let body,
           body.localizedCaseInsensitiveContains("limited to 1 convert options") {
            return true
        }

        return false
    }
}

private struct CoinMarketCapResponse: Decodable {
    let data: [String: CoinMarketCapAsset]
}

private struct CoinMarketCapAsset: Decodable {
    let quote: [String: CurrencyQuote]
}

private struct CoinGeckoResponse: Decodable {
    let marketData: CoinGeckoMarketData

    private enum CodingKeys: String, CodingKey {
        case marketData = "market_data"
    }
}

private struct CoinGeckoMarketData: Decodable {
    let currentPrice: [String: Double]
    let totalVolume: [String: Double]
    let priceChangePercentage1hInCurrency: [String: Double]?
    let priceChangePercentage24hInCurrency: [String: Double]?
    let priceChangePercentage7dInCurrency: [String: Double]?
    let priceChangePercentage30dInCurrency: [String: Double]?

    private enum CodingKeys: String, CodingKey {
        case currentPrice = "current_price"
        case totalVolume = "total_volume"
        case priceChangePercentage1hInCurrency = "price_change_percentage_1h_in_currency"
        case priceChangePercentage24hInCurrency = "price_change_percentage_24h_in_currency"
        case priceChangePercentage7dInCurrency = "price_change_percentage_7d_in_currency"
        case priceChangePercentage30dInCurrency = "price_change_percentage_30d_in_currency"
    }
}

private extension Data {
    func debugSnippet(limit: Int = 240) -> String? {
        guard let text = String(data: self, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !text.isEmpty
        else {
            return nil
        }

        if text.count <= limit {
            return text
        }

        let endIndex = text.index(text.startIndex, offsetBy: limit)
        return String(text[..<endIndex]) + "..."
    }
}
