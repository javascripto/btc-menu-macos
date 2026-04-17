import Foundation

enum PriceMovement {
    case up
    case down
    case unchanged

    var symbol: String {
        switch self {
        case .up:
            return "↑"
        case .down:
            return "↓"
        case .unchanged:
            return "→"
        }
    }
}

struct BTCMenuState {
    let statusTitle: String
    let quoteMovements: QuoteMovements
    let displayOptions: DisplayOptions
    let launchesAtLogin: Bool
    let lastUpdateDescription: String
    let change1hDescription: String
    let change3hDescription: String
    let change24hDescription: String
    let volumeDescription: String
    let priceSourceDescription: String
    let lastErrorDescription: String?
    let hasErrorDetails: Bool
    let apiKeyConfigured: Bool
    let alertEnabled: Bool

    var alertTitle: String {
        alertEnabled ? "Editar alerta de preço/variação" : "Definir alerta de preço/variação"
    }

    var apiKeyTitle: String {
        apiKeyConfigured ? "Atualizar API Key da CoinMarketCap" : "Definir API Key da CoinMarketCap"
    }

    var launchAtLoginTitle: String {
        "Iniciar com o macOS"
    }

    var errorTitle: String {
        hasErrorDetails ? "Mostrar último erro" : "Nenhum erro recente"
    }
}
