// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DepoKit",
    platforms: [
        .iOS(.v18),
        .macOS(.v13),
    ],
    products: [
        .library(name: "DepoCore", targets: ["DepoCore"]),
        .library(name: "DepoLiveActivity", targets: ["DepoLiveActivity"]),
        .library(name: "DepoUI", targets: ["DepoUI"]),
    ],
    targets: [
        .target(
            name: "DepoCore",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .target(
            name: "DepoLiveActivity",
            dependencies: ["DepoCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .target(
            name: "DepoUI",
            dependencies: ["DepoCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
