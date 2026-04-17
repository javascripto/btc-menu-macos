import AppKit
import Foundation
import UserNotifications

@MainActor
protocol AlertServicing {
    func notify(title: String, message: String)
    func beep()
}

@MainActor
final class AlertService: AlertServicing {
    static let shared = AlertService()

    private let center = UNUserNotificationCenter.current()

    init() {
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                AppLogger.alerts.error("Notification authorization failed: \(String(describing: error), privacy: .public)")
                return
            }

            AppLogger.alerts.info("Notification authorization granted=\(granted, privacy: .public)")
        }
    }

    func notify(title: String, message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        center.add(request) { error in
            if let error {
                AppLogger.alerts.error("Notification schedule failed: \(String(describing: error), privacy: .public)")
                return
            }

            AppLogger.alerts.info("Notification scheduled: \(title, privacy: .public) | \(message, privacy: .public)")
        }
    }

    func beep() {
        NSSound(named: NSSound.Name("Ping"))?.play()
    }
}
