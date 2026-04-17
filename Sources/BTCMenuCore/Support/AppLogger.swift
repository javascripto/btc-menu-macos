import OSLog

enum AppLogger {
    static let pricing = Logger(subsystem: "com.yuri.btcmenu", category: "pricing")
    static let alerts = Logger(subsystem: "com.yuri.btcmenu", category: "alerts")
}
