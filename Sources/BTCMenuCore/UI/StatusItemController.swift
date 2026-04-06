import AppKit

@MainActor
final class BTCStatusItemController: NSObject {
    private let statusItem: NSStatusItem
    private let onManualUpdate: () -> Void
    private let onSelectCurrency: (Currency) -> Void
    private let onConfigureAlert: () -> Void
    private let onConfigureAPIKey: () -> Void
    private let onToggleLaunchAtLogin: () -> Void
    private let onShowLastError: () -> Void
    private let onQuit: () -> Void

    private let menu = NSMenu()
    private let manualUpdateItem = NSMenuItem()
    private let lastUpdateItem = NSMenuItem()
    private let change24hItem = NSMenuItem()
    private let volumeItem = NSMenuItem()
    private let sourceItem = NSMenuItem()
    private let errorItem = NSMenuItem()
    private let currencyMenuItem = NSMenuItem(title: "Moeda", action: nil, keyEquivalent: "")
    private let currencyMenu = NSMenu()
    private let usdItem = NSMenuItem()
    private let brlItem = NSMenuItem()
    private let alertItem = NSMenuItem()
    private let apiKeyItem = NSMenuItem()
    private let launchAtLoginItem = NSMenuItem()
    private let quitItem = NSMenuItem()

    init(
        statusItem: NSStatusItem,
        onManualUpdate: @escaping () -> Void,
        onSelectCurrency: @escaping (Currency) -> Void,
        onConfigureAlert: @escaping () -> Void,
        onConfigureAPIKey: @escaping () -> Void,
        onToggleLaunchAtLogin: @escaping () -> Void,
        onShowLastError: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.statusItem = statusItem
        self.onManualUpdate = onManualUpdate
        self.onSelectCurrency = onSelectCurrency
        self.onConfigureAlert = onConfigureAlert
        self.onConfigureAPIKey = onConfigureAPIKey
        self.onToggleLaunchAtLogin = onToggleLaunchAtLogin
        self.onShowLastError = onShowLastError
        self.onQuit = onQuit
        super.init()
        configure()
    }

    func update(state: BTCMenuState) {
        applyStatusTitle(state: state)
        statusItem.button?.toolTip = state.statusTitle
        lastUpdateItem.title = state.lastUpdateDescription
        change24hItem.title = state.change24hDescription
        volumeItem.title = state.volumeDescription
        sourceItem.title = state.priceSourceDescription
        errorItem.title = state.errorTitle
        errorItem.toolTip = state.lastErrorDescription
        errorItem.isEnabled = state.hasErrorDetails
        usdItem.state = state.currency == .usd ? .on : .off
        brlItem.state = state.currency == .brl ? .on : .off
        alertItem.title = state.alertTitle
        apiKeyItem.title = state.apiKeyTitle
        launchAtLoginItem.title = state.launchAtLoginTitle
        launchAtLoginItem.state = state.launchesAtLogin ? .on : .off
    }

    private func configure() {
        guard let button = statusItem.button else { return }

        statusItem.menu = menu
        button.title = "₿ --"

        lastUpdateItem.isEnabled = false
        change24hItem.isEnabled = false
        volumeItem.isEnabled = false
        sourceItem.isEnabled = false
        errorItem.isEnabled = false
        errorItem.title = "Nenhum erro recente"

        manualUpdateItem.title = "Atualizar agora"
        manualUpdateItem.target = self
        manualUpdateItem.action = #selector(handleManualUpdate)

        usdItem.title = "USD"
        usdItem.target = self
        usdItem.action = #selector(handleUSD)

        brlItem.title = "BRL"
        brlItem.target = self
        brlItem.action = #selector(handleBRL)

        currencyMenu.autoenablesItems = false
        currencyMenu.items = [usdItem, brlItem]
        currencyMenuItem.submenu = currencyMenu

        alertItem.target = self
        alertItem.action = #selector(handleAlert)

        apiKeyItem.target = self
        apiKeyItem.action = #selector(handleAPIKey)

        launchAtLoginItem.target = self
        launchAtLoginItem.action = #selector(handleLaunchAtLogin)

        errorItem.target = self
        errorItem.action = #selector(handleShowLastError)

        quitItem.title = "Sair"
        quitItem.keyEquivalent = "q"
        quitItem.target = self
        quitItem.action = #selector(handleQuit)

        menu.autoenablesItems = false
        menu.items = [
            manualUpdateItem,
            .separator(),
            lastUpdateItem,
            change24hItem,
            volumeItem,
            sourceItem,
            errorItem,
            .separator(),
            currencyMenuItem,
            alertItem,
            apiKeyItem,
            launchAtLoginItem,
            .separator(),
            quitItem,
        ]
    }

    @objc
    private func handleManualUpdate() { onManualUpdate() }

    @objc
    private func handleUSD() { onSelectCurrency(.usd) }

    @objc
    private func handleBRL() { onSelectCurrency(.brl) }

    @objc
    private func handleAlert() { onConfigureAlert() }

    @objc
    private func handleAPIKey() { onConfigureAPIKey() }

    @objc
    private func handleLaunchAtLogin() { onToggleLaunchAtLogin() }

    @objc
    private func handleShowLastError() { onShowLastError() }

    @objc
    private func handleQuit() { onQuit() }

    private func applyStatusTitle(state: BTCMenuState) {
        guard let button = statusItem.button else { return }

        let title = state.statusTitle
        let attributedTitle = NSMutableAttributedString(string: title)
        let wholeRange = NSRange(location: 0, length: attributedTitle.length)
        attributedTitle.addAttribute(.foregroundColor, value: NSColor.labelColor, range: wholeRange)

        if let firstCharacter = title.first {
            let arrowColor: NSColor
            switch state.priceMovement {
            case .up:
                arrowColor = .systemGreen
            case .down:
                arrowColor = .systemRed
            case .unchanged:
                arrowColor = .labelColor
            }

            let arrowLength = String(firstCharacter).utf16.count
            attributedTitle.addAttribute(.foregroundColor, value: arrowColor, range: NSRange(location: 0, length: arrowLength))
        }

        button.attributedTitle = attributedTitle
    }
}
