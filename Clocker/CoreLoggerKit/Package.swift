// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CoreLoggerKit",
    platforms: [
        .macOS(.v10_12)
    ],
    products: [
        .library(
            name: "CoreLoggerKit",
            targets: ["CoreLoggerKit"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CoreLoggerKit",
            dependencies: []
        ),
        .testTarget(
            name: "CoreLoggerKitTests",
            dependencies: ["CoreLoggerKit"]
        )
    ]
)
