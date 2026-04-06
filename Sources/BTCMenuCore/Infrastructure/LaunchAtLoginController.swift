import Foundation
import ServiceManagement

@MainActor
protocol LaunchAtLoginControlling {
    var launchesAtLogin: Bool { get }
    func setLaunchesAtLogin(_ isEnabled: Bool)
}

@MainActor
final class LaunchAtLoginController: LaunchAtLoginControlling {
    private let appService = SMAppService.mainApp

    var launchesAtLogin: Bool {
        switch appService.status {
        case .enabled, .requiresApproval:
            return true
        case .notRegistered, .notFound:
            return false
        @unknown default:
            return false
        }
    }

    func setLaunchesAtLogin(_ isEnabled: Bool) {
        do {
            if isEnabled {
                try appService.register()
                if appService.status == .requiresApproval {
                    SMAppService.openSystemSettingsLoginItems()
                }
            } else {
                try appService.unregister()
            }
        } catch {
            if isEnabled {
                SMAppService.openSystemSettingsLoginItems()
            }
            AppLogger.pricing.error("Failed to update launch at login setting: \(String(describing: error), privacy: .public)")
        }
    }
}
