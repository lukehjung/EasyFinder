// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EasyFinder",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "EasyFinder", targets: ["EasyFinder"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "EasyFinder",
            dependencies: [],
            path: "Sources/EasyFinder"
        )
    ]
)
