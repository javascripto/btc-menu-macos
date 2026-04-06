import Foundation

struct BTCQuote: Decodable {
    let price: Double
    let volume24h: Double
    let percentChange1h: Double?
    let percentChange3h: Double?
    let percentChange24h: Double?

    private enum CodingKeys: String, CodingKey {
        case price
        case volume24h = "volume_24h"
        case percentChange1h = "percent_change_1h"
        case percentChange3h = "percent_change_3h"
        case percentChange24h = "percent_change_24h"
    }
}

protocol BTCQuoteClient: Sendable {
    func fetchBTCQuote(
        apiKey: String?,
        currency: Currency,
        preference: PriceSourcePreference
    ) async throws -> BTCQuote
}

struct LiveBTCQuoteClient: BTCQuoteClient, Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchBTCQuote(
        apiKey: String?,
        currency: Currency,
        preference: PriceSourcePreference
    ) async throws -> BTCQuote {
        if preference == .coinMarketCap, let apiKey, !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            AppLogger.pricing.info("Request start: source=coinmarketcap currency=\(currency.rawValue, privacy: .public)")
            do {
                let quote = try await fetchCoinMarketCapQuote(apiKey: apiKey, currency: currency)
                AppLogger.pricing.info(
                    "Request success: source=coinmarketcap currency=\(currency.rawValue, privacy: .public) price=\(quote.price, privacy: .public)"
                )
                return quote
            } catch let error as APIError where error.isRateLimited {
                AppLogger.pricing.warning(
                    "Request fallback: source=coinmarketcap currency=\(currency.rawValue, privacy: .public) reason=\(error.debugDescription, privacy: .public)"
                )
                AppLogger.pricing.info("Request start: source=coingecko currency=\(currency.rawValue, privacy: .public)")
                let quote = try await fetchCoinGeckoQuote(currency: currency)
                AppLogger.pricing.info(
                    "Request success: source=coingecko currency=\(currency.rawValue, privacy: .public) price=\(quote.price, privacy: .public)"
                )
                return quote
            } catch {
                AppLogger.pricing.error(
                    "Request failure: source=coinmarketcap currency=\(currency.rawValue, privacy: .public) error=\(String(describing: error), privacy: .public)"
                )
                throw error
            }
        }

        if preference == .coinMarketCap {
            AppLogger.pricing.warning(
                "Request fallback: source=coinmarketcap currency=\(currency.rawValue, privacy: .public) reason=no_api_key_configured"
            )
        }

        AppLogger.pricing.info("Request start: source=coingecko currency=\(currency.rawValue, privacy: .public)")
        do {
            let quote = try await fetchCoinGeckoQuote(currency: currency)
            AppLogger.pricing.info(
                "Request success: source=coingecko currency=\(currency.rawValue, privacy: .public) price=\(quote.price, privacy: .public)"
            )
            return quote
        } catch {
            AppLogger.pricing.error(
                "Request failure: source=coingecko currency=\(currency.rawValue, privacy: .public) error=\(String(describing: error), privacy: .public)"
            )
            throw error
        }
    }

    private func fetchCoinMarketCapQuote(apiKey: String, currency: Currency) async throws -> BTCQuote {
        var components = URLComponents(string: "https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest")
        components?.queryItems = [
            URLQueryItem(name: "symbol", value: "BTC"),
            URLQueryItem(name: "convert", value: currency.rawValue.uppercased()),
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
        guard let quote = decoded.data["BTC"]?.quote[currency.rawValue.uppercased()] else {
            throw APIError.missingQuote
        }

        return quote
    }

    private func fetchCoinGeckoQuote(currency: Currency) async throws -> BTCQuote {
        var components = URLComponents(string: "https://api.coingecko.com/api/v3/coins/bitcoin")
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
        let marketData = decoded.marketData

        let price = try value(for: marketData.currentPrice, currency: currency)
        let volume24h = try value(for: marketData.totalVolume, currency: currency)

        return BTCQuote(
            price: price,
            volume24h: volume24h,
            percentChange1h: try? marketData.priceChangePercentage1hInCurrency.flatMap { try value(for: $0, currency: currency) },
            percentChange3h: nil,
            percentChange24h: try? marketData.priceChangePercentage24hInCurrency.flatMap { try value(for: $0, currency: currency) }
        )
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
            return "Cotação BTC não encontrada na resposta da API"
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
}

private struct CoinMarketCapResponse: Decodable {
    let data: [String: CoinMarketCapAsset]
}

private struct CoinMarketCapAsset: Decodable {
    let quote: [String: BTCQuote]
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

    private enum CodingKeys: String, CodingKey {
        case currentPrice = "current_price"
        case totalVolume = "total_volume"
        case priceChangePercentage1hInCurrency = "price_change_percentage_1h_in_currency"
        case priceChangePercentage24hInCurrency = "price_change_percentage_24h_in_currency"
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
