import AppKit
import BTCMenuCore

let app = NSApplication.shared
let appDelegate = AppDelegate()

app.setActivationPolicy(.accessory)
app.delegate = appDelegate
app.run()
