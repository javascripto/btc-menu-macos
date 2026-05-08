import Foundation

struct PriceSample: Codable, Equatable {
    let timestamp: Date
    let btcBRL: Double
    let ethBRL: Double
}
