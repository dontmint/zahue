// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ZaHue",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ZaHue", targets: ["ZaHue"])
    ],
    targets: [
        .executableTarget(
            name: "ZaHue",
            path: "Sources/ZaHue"
        )
    ]
)
