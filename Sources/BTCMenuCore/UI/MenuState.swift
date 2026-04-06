import Foundation

enum PriceMovement {
    case up
    case down
    case unchanged
}

struct BTCMenuState {
    let statusTitle: String
    let priceMovement: PriceMovement
    let currency: Currency
    let launchesAtLogin: Bool
    let lastUpdateDescription: String
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
