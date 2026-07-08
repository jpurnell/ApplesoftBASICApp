// swift-tools-version: 6.2
// legibility:description: An iPad app that interprets and runs Applesoft BASIC programs with a retro terminal experience.
import PackageDescription

let package = Package(
    name: "ApplesoftBASICAppCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ApplesoftBASICAppCore",
            targets: ["ApplesoftBASICAppCore"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.0")
    ],
    targets: [
        .target(
            name: "ApplesoftBASICAppCore"
        ),
        .testTarget(
            name: "ApplesoftBASICAppCoreTests",
            dependencies: ["ApplesoftBASICAppCore"]
        )
    ]
)
