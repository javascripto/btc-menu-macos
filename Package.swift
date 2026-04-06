// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BTCMenu",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(
            name: "BTCMenu",
            targets: ["BTCMenuApp"]
        ),
        .library(
            name: "BTCMenuCore",
            targets: ["BTCMenuCore"]
        ),
    ],
    targets: [
        .target(
            name: "BTCMenuCore",
            linkerSettings: [
                .linkedFramework("UserNotifications"),
            ]
        ),
        .executableTarget(
            name: "BTCMenuApp",
            dependencies: ["BTCMenuCore"]
        ),
    ]
)
