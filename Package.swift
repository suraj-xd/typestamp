// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Typestamp",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.0.0"),
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts.git", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "TypestampKit",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            path: "Sources/TypestampKit"
        ),
        .executableTarget(
            name: "Typestamp",
            dependencies: [
                "TypestampKit",
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
            ],
            path: "Sources/Typestamp"
        ),
        .testTarget(
            name: "TypestampKitTests",
            dependencies: ["TypestampKit"],
            path: "Tests/TypestampKitTests"
        ),
    ]
)
