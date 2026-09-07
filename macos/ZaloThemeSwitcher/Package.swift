// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ZaloThemeSwitcher",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ZaloThemeSwitcher", targets: ["ZaloThemeSwitcher"])
    ],
    targets: [
        .executableTarget(
            name: "ZaloThemeSwitcher",
            path: "Sources/ZaloThemeSwitcher"
        )
    ]
)
