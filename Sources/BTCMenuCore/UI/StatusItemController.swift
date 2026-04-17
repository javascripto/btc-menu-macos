import AppKit

@MainActor
final class BTCStatusItemController: NSObject {
    private let statusItem: NSStatusItem
    private let onManualUpdate: () -> Void
    private let onToggleDollarRate: () -> Void
    private let onToggleBitcoinUSD: () -> Void
    private let onToggleBitcoinBRL: () -> Void
    private let onToggleBitcoinCents: () -> Void
    private let onConfigureAlert: () -> Void
    private let onConfigureAPIKey: () -> Void
    private let onToggleLaunchAtLogin: () -> Void
    private let onShowLastError: () -> Void
    private let onQuit: () -> Void

    private let menu = NSMenu()
    private let manualUpdateItem = NSMenuItem()
    private let lastUpdateItem = NSMenuItem()
    private let change1hItem = NSMenuItem()
    private let change24hItem = NSMenuItem()
    private let change7dItem = NSMenuItem()
    private let change30dItem = NSMenuItem()
    private let volumeItem = NSMenuItem()
    private let sourceItem = NSMenuItem()
    private let errorItem = NSMenuItem()
    private let displayMenuItem = NSMenuItem(title: "Exibir", action: nil, keyEquivalent: "")
    private let displayMenu = NSMenu()
    private let dollarRateItem = NSMenuItem()
    private let bitcoinUSDItem = NSMenuItem()
    private let bitcoinBRLItem = NSMenuItem()
    private let bitcoinCentsItem = NSMenuItem()
    private let alertItem = NSMenuItem()
    private let apiKeyItem = NSMenuItem()
    private let launchAtLoginItem = NSMenuItem()
    private let quitItem = NSMenuItem()

    init(
        statusItem: NSStatusItem,
        onManualUpdate: @escaping () -> Void,
        onToggleDollarRate: @escaping () -> Void,
        onToggleBitcoinUSD: @escaping () -> Void,
        onToggleBitcoinBRL: @escaping () -> Void,
        onToggleBitcoinCents: @escaping () -> Void,
        onConfigureAlert: @escaping () -> Void,
        onConfigureAPIKey: @escaping () -> Void,
        onToggleLaunchAtLogin: @escaping () -> Void,
        onShowLastError: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.statusItem = statusItem
        self.onManualUpdate = onManualUpdate
        self.onToggleDollarRate = onToggleDollarRate
        self.onToggleBitcoinUSD = onToggleBitcoinUSD
        self.onToggleBitcoinBRL = onToggleBitcoinBRL
        self.onToggleBitcoinCents = onToggleBitcoinCents
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
        applyChangeTitle(change1hItem, title: state.change1hDescription)
        applyChangeTitle(change24hItem, title: state.change24hDescription)
        applyChangeTitle(change7dItem, title: state.change7dDescription)
        applyChangeTitle(change30dItem, title: state.change30dDescription)
        volumeItem.title = state.volumeDescription
        sourceItem.title = state.priceSourceDescription
        errorItem.title = state.errorTitle
        errorItem.toolTip = state.lastErrorDescription
        errorItem.isEnabled = state.hasErrorDetails
        dollarRateItem.state = state.displayOptions.showDollarRate ? .on : .off
        bitcoinUSDItem.state = state.displayOptions.showBitcoinUSD ? .on : .off
        bitcoinBRLItem.state = state.displayOptions.showBitcoinBRL ? .on : .off
        bitcoinCentsItem.state = state.displayOptions.showBitcoinCents ? .on : .off
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
        change1hItem.isEnabled = false
        change24hItem.isEnabled = false
        change7dItem.isEnabled = false
        change30dItem.isEnabled = false
        volumeItem.isEnabled = false
        sourceItem.isEnabled = false
        errorItem.isEnabled = false
        errorItem.title = "Nenhum erro recente"

        manualUpdateItem.title = "Atualizar agora"
        manualUpdateItem.target = self
        manualUpdateItem.action = #selector(handleManualUpdate)

        dollarRateItem.title = "Cotação do dólar"
        dollarRateItem.target = self
        dollarRateItem.action = #selector(handleDollarRate)

        bitcoinUSDItem.title = "Bitcoin em dólar"
        bitcoinUSDItem.target = self
        bitcoinUSDItem.action = #selector(handleBitcoinUSD)

        bitcoinBRLItem.title = "Bitcoin em real"
        bitcoinBRLItem.target = self
        bitcoinBRLItem.action = #selector(handleBitcoinBRL)

        bitcoinCentsItem.title = "Mostrar centavos do Bitcoin"
        bitcoinCentsItem.target = self
        bitcoinCentsItem.action = #selector(handleBitcoinCents)

        displayMenu.autoenablesItems = false
        displayMenu.items = [dollarRateItem, bitcoinUSDItem, bitcoinBRLItem, .separator(), bitcoinCentsItem]
        displayMenuItem.submenu = displayMenu

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
            change1hItem,
            change24hItem,
            change7dItem,
            change30dItem,
            volumeItem,
            sourceItem,
            errorItem,
            .separator(),
            displayMenuItem,
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
    private func handleDollarRate() { onToggleDollarRate() }

    @objc
    private func handleBitcoinUSD() { onToggleBitcoinUSD() }

    @objc
    private func handleBitcoinBRL() { onToggleBitcoinBRL() }

    @objc
    private func handleBitcoinCents() { onToggleBitcoinCents() }

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

        let movementBySymbol: [Character: PriceMovement] = [
            "↑": .up,
            "↓": .down,
            "→": .unchanged,
        ]

        for (offset, character) in title.enumerated() {
            guard let movement = movementBySymbol[character] else { continue }

            let color: NSColor
            switch movement {
            case .up:
                color = .systemGreen
            case .down:
                color = .systemRed
            case .unchanged:
                color = .labelColor
            }

            let stringIndex = title.index(title.startIndex, offsetBy: offset)
            let location = title[..<stringIndex].utf16.count
            let length = String(character).utf16.count
            attributedTitle.addAttribute(.foregroundColor, value: color, range: NSRange(location: location, length: length))
        }

        button.attributedTitle = attributedTitle
    }

    private func applyChangeTitle(_ item: NSMenuItem, title: String) {
        let attributedTitle = NSMutableAttributedString(string: title)
        let wholeRange = NSRange(location: 0, length: attributedTitle.length)
        attributedTitle.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: wholeRange)

        if let range = title.range(of: "↑") {
            let nsRange = NSRange(range, in: title)
            attributedTitle.addAttribute(.foregroundColor, value: NSColor.systemGreen, range: nsRange)
        } else if let range = title.range(of: "↓") {
            let nsRange = NSRange(range, in: title)
            attributedTitle.addAttribute(.foregroundColor, value: NSColor.systemRed, range: nsRange)
        }

        item.attributedTitle = attributedTitle
    }
}
