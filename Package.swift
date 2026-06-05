// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WeReadScreenSaver",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "WeReadScreenSaver",
            targets: ["WeReadScreenSaver"]
        )
    ],
    targets: [
        .executableTarget(
            name: "WeReadScreenSaver",
            path: "Sources/WeReadScreenSaver",
            linkerSettings: [
                .linkedFramework("Security"),
                .linkedLibrary("sqlite3")
            ]
        )
    ]
)
