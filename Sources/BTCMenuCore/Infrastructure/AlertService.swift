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
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
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
        center.add(request)
    }

    func beep() {
        NSSound(named: NSSound.Name("Ping"))?.play()
    }
}
