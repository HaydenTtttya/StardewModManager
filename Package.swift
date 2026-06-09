// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "StardewModManager",
    defaultLocalization: "zh-Hans",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "StardewModCore",
            targets: ["StardewModCore"]
        ),
        .executable(
            name: "StardewModManager",
            targets: ["StardewModManager"]
        )
    ],
    targets: [
        .target(
            name: "StardewModCore"
        ),
        .executableTarget(
            name: "StardewModManager",
            dependencies: ["StardewModCore"]
        ),
        .testTarget(
            name: "StardewModCoreTests",
            dependencies: ["StardewModCore"]
        )
    ]
)
