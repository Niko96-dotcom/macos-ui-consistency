// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ConsistencyFixture",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ConsistencyFixture", targets: ["ConsistencyFixture"])
    ],
    targets: [
        .executableTarget(
            name: "ConsistencyFixture",
            path: "Sources/ConsistencyFixture"
        )
    ]
)
