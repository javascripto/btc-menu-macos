import Foundation

struct DisplayOptions: Equatable {
    var showDollarRate: Bool
    var showBitcoinUSD: Bool
    var showBitcoinBRL: Bool
    var showEthereumUSD: Bool
    var showBitcoinCents: Bool

    static let `default` = DisplayOptions(
        showDollarRate: false,
        showBitcoinUSD: true,
        showBitcoinBRL: false,
        showEthereumUSD: true,
        showBitcoinCents: false
    )
}

struct QuoteSnapshot: Equatable {
    let btcUSD: Double
    let btcBRL: Double
    let ethUSD: Double
    let ethBRL: Double
    let usdBRL: Double
    let btcUSDVolume24h: Double
    let btcBRLVolume24h: Double
    let ethUSDVolume24h: Double
    let ethBRLVolume24h: Double
    let btcUSDPercentChange1h: Double?
    let btcBRLPercentChange1h: Double?
    let ethUSDPercentChange1h: Double?
    let ethBRLPercentChange1h: Double?
    let btcUSDPercentChange24h: Double?
    let btcBRLPercentChange24h: Double?
    let ethUSDPercentChange24h: Double?
    let ethBRLPercentChange24h: Double?
    let btcUSDPercentChange7d: Double?
    let btcBRLPercentChange7d: Double?
    let ethUSDPercentChange7d: Double?
    let ethBRLPercentChange7d: Double?
    let btcUSDPercentChange30d: Double?
    let btcBRLPercentChange30d: Double?
    let ethUSDPercentChange30d: Double?
    let ethBRLPercentChange30d: Double?

    func primaryBTCQuote() -> PrimaryBTCQuote {
        PrimaryBTCQuote(
            currency: .brl,
            price: btcBRL,
            volume24h: btcBRLVolume24h,
            percentChange1h: btcBRLPercentChange1h,
            percentChange24h: btcBRLPercentChange24h,
            percentChange7d: btcBRLPercentChange7d,
            percentChange30d: btcBRLPercentChange30d
        )
    }
}

struct PrimaryBTCQuote {
    let currency: Currency
    let price: Double
    let volume24h: Double
    let percentChange1h: Double?
    let percentChange24h: Double?
    let percentChange7d: Double?
    let percentChange30d: Double?
}

struct QuoteMovements: Equatable {
    let btcUSD: PriceMovement
    let btcBRL: PriceMovement
    let ethUSD: PriceMovement
    let ethBRL: PriceMovement
    let usdBRL: PriceMovement
}

enum StatusTitleBuilder {
    static func build(snapshot: QuoteSnapshot?, options: DisplayOptions, movements: QuoteMovements?) -> String {
        guard let snapshot else { return "--" }

        let currentMovements = movements ?? QuoteMovements(
            btcUSD: .unchanged,
            btcBRL: .unchanged,
            ethUSD: .unchanged,
            ethBRL: .unchanged,
            usdBRL: .unchanged
        )

        var segments: [String] = []
        let bitcoinUSDText = options.showBitcoinCents ? Formatting.price(snapshot.btcUSD) : Formatting.compactPrice(snapshot.btcUSD)
        let bitcoinBRLText = options.showBitcoinCents ? Formatting.price(snapshot.btcBRL) : Formatting.compactPrice(snapshot.btcBRL)
        let ethereumUSDText = options.showBitcoinCents ? Formatting.price(snapshot.ethUSD) : Formatting.compactPrice(snapshot.ethUSD)

        if options.showBitcoinUSD {
            segments.append("\(currentMovements.btcUSD.symbol) ₿ $\(bitcoinUSDText)")
        }

        if options.showBitcoinBRL {
            segments.append("\(currentMovements.btcBRL.symbol) ₿ R$\(bitcoinBRLText)")
        }

        if options.showEthereumUSD {
            segments.append("\(currentMovements.ethUSD.symbol) Ξ $\(ethereumUSDText)")
        }

        if options.showDollarRate {
            segments.append("\(currentMovements.usdBRL.symbol) $ R$\(Formatting.exchangeRate(snapshot.usdBRL))")
        }

        return segments.isEmpty ? "--" : segments.joined(separator: " | ")
    }
}
