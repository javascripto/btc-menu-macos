import AppKit
import SwiftUI

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private let viewModel = BTCMenuViewModel()
    private var statusItemController: BTCStatusItemController?
    private var timer: Timer?
    private var popoverPresenter: StatusItemPopoverPresenter?
    private let errorWindowPresenter = ErrorDetailsWindowPresenter()

    public override init() {}

    public func applicationDidFinishLaunching(_ notification: Notification) {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popoverPresenter = StatusItemPopoverPresenter(statusItem: statusItem)
        statusItemController = BTCStatusItemController(
            statusItem: statusItem,
            onManualUpdate: { [viewModel] in
                Task { await viewModel.updatePrice(force: true) }
            },
            onToggleDollarRate: { [viewModel] in
                Task {
                    var options = viewModel.displayOptions
                    options.showDollarRate.toggle()
                    await viewModel.setDisplayOptions(options)
                }
            },
            onToggleBitcoinUSD: { [viewModel] in
                Task {
                    var options = viewModel.displayOptions
                    options.showBitcoinUSD.toggle()
                    await viewModel.setDisplayOptions(options)
                }
            },
            onToggleBitcoinBRL: { [viewModel] in
                Task {
                    var options = viewModel.displayOptions
                    options.showBitcoinBRL.toggle()
                    await viewModel.setDisplayOptions(options)
                }
            },
            onToggleBitcoinCents: { [viewModel] in
                Task {
                    var options = viewModel.displayOptions
                    options.showBitcoinCents.toggle()
                    await viewModel.setDisplayOptions(options)
                }
            },
            onConfigureAlert: { [weak self] in
                self?.openAlertConfiguration()
            },
            onConfigureAPIKey: { [weak self] in
                self?.openAPIKeyPrompt()
            },
            onToggleLaunchAtLogin: { [viewModel] in
                viewModel.setLaunchAtLogin(!viewModel.launchesAtLogin)
            },
            onShowLastError: { [weak self] in
                self?.showLastError()
            },
            onQuit: { [viewModel] in
                viewModel.quit()
            }
        )

        viewModel.onStateChange = { [weak self] state in
            self?.statusItemController?.update(state: state)
        }
        viewModel.emitState()

        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [viewModel] _ in
            Task { await viewModel.updatePrice(force: false) }
        }

        Task { await viewModel.start() }
    }

    public func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
    }

    private func openAPIKeyPrompt() {
        let initialSourcePreference = viewModel.priceSourcePreference
        let initialValue = viewModel.apiKey
        popoverPresenter?.show {
            APIKeyPopoverView(
                initialSourcePreference: initialSourcePreference,
                initialAPIKey: initialValue,
                onSave: { [weak self] sourcePreference, value in
                    self?.popoverPresenter?.close()
                    Task {
                        self?.viewModel.setPriceSourcePreference(sourcePreference)
                        await self?.viewModel.setAPIKey(value.trimmingCharacters(in: .whitespacesAndNewlines))
                        await self?.viewModel.updatePrice(force: true)
                    }
                },
                onCancel: { [weak self] in
                    self?.popoverPresenter?.close()
                }
            )
        }
    }

    private func openAlertConfiguration() {
        let initialConfig = viewModel.alertConfig
        popoverPresenter?.show {
            AlertPopoverView(
                initialConfig: initialConfig,
                onSave: { [weak self] config in
                    self?.popoverPresenter?.close()
                    self?.viewModel.setAlertConfig(config)
                },
                onTest: { [weak self] in
                    self?.viewModel.playTestAlert()
                },
                onCancel: { [weak self] in
                    self?.popoverPresenter?.close()
                }
            )
        }
    }

    private func showLastError() {
        guard let details = viewModel.lastErrorDetails else { return }
        errorWindowPresenter.show(details: details)
    }
}
