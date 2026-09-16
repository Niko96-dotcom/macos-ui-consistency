// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ConsistencyFixture",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ConsistencyFixture", targets: ["ConsistencyFixture"]),
        .executable(name: "SettingsFixture", targets: ["SettingsFixture"]),
        .executable(name: "AdversarialFixture", targets: ["AdversarialFixture"]),
        .executable(name: "UtilityFixture", targets: ["UtilityFixture"]),
        .executable(name: "EditorFixture", targets: ["EditorFixture"]),
        .executable(name: "WorkspaceFixture", targets: ["WorkspaceFixture"]),
    ],
    targets: [
        .executableTarget(
            name: "ConsistencyFixture",
            path: "Sources/ConsistencyFixture"
        ),
        .executableTarget(
            name: "SettingsFixture",
            path: "Sources/SettingsFixture"
        ),
        .executableTarget(
            name: "AdversarialFixture",
            path: "Sources/AdversarialFixture"
        ),
        .executableTarget(
            name: "UtilityFixture",
            path: "Sources/UtilityFixture"
        ),
        .executableTarget(
            name: "EditorFixture",
            path: "Sources/EditorFixture"
        ),
        .executableTarget(
            name: "WorkspaceFixture",
            path: "Sources/WorkspaceFixture"
        ),
    ]
)
