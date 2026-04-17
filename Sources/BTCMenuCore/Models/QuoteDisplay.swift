import Foundation

struct DisplayOptions: Equatable {
    var showDollarRate: Bool
    var showBitcoinUSD: Bool
    var showBitcoinBRL: Bool
    var showBitcoinCents: Bool

    static let `default` = DisplayOptions(
        showDollarRate: false,
        showBitcoinUSD: true,
        showBitcoinBRL: false,
        showBitcoinCents: false
    )
}

struct QuoteSnapshot: Equatable {
    let btcUSD: Double
    let btcBRL: Double
    let usdBRL: Double
    let btcUSDVolume24h: Double
    let btcBRLVolume24h: Double
    let btcUSDPercentChange1h: Double?
    let btcBRLPercentChange1h: Double?
    let btcUSDPercentChange3h: Double?
    let btcBRLPercentChange3h: Double?
    let btcUSDPercentChange24h: Double?
    let btcBRLPercentChange24h: Double?

    func primaryBTCQuote() -> PrimaryBTCQuote {
        PrimaryBTCQuote(
            currency: .brl,
            price: btcBRL,
            volume24h: btcBRLVolume24h,
            percentChange1h: btcBRLPercentChange1h,
            percentChange3h: btcBRLPercentChange3h,
            percentChange24h: btcBRLPercentChange24h
        )
    }
}

struct PrimaryBTCQuote {
    let currency: Currency
    let price: Double
    let volume24h: Double
    let percentChange1h: Double?
    let percentChange3h: Double?
    let percentChange24h: Double?
}

struct QuoteMovements: Equatable {
    let btcUSD: PriceMovement
    let btcBRL: PriceMovement
    let usdBRL: PriceMovement
}

enum StatusTitleBuilder {
    static func build(snapshot: QuoteSnapshot?, options: DisplayOptions, movements: QuoteMovements?) -> String {
        guard let snapshot else { return "--" }

        let currentMovements = movements ?? QuoteMovements(
            btcUSD: .unchanged,
            btcBRL: .unchanged,
            usdBRL: .unchanged
        )

        var segments: [String] = []
        let bitcoinUSDText = options.showBitcoinCents ? Formatting.price(snapshot.btcUSD) : Formatting.compactPrice(snapshot.btcUSD)
        let bitcoinBRLText = options.showBitcoinCents ? Formatting.price(snapshot.btcBRL) : Formatting.compactPrice(snapshot.btcBRL)

        if options.showBitcoinUSD {
            segments.append("\(currentMovements.btcUSD.symbol) ₿ $\(bitcoinUSDText)")
        }

        if options.showBitcoinBRL {
            segments.append("\(currentMovements.btcBRL.symbol) ₿ R$\(bitcoinBRLText)")
        }

        if options.showDollarRate {
            segments.append("\(currentMovements.usdBRL.symbol) $ R$\(Formatting.exchangeRate(snapshot.usdBRL))")
        }

        return segments.isEmpty ? "--" : segments.joined(separator: " | ")
    }
}
