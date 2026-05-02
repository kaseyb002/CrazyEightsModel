// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CrazyEightsModel",
    platforms: [
        .iOS(.v17),
        .macOS(.v12),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(
            name: "CrazyEightsModel",
            targets: ["CrazyEightsModel"]
        ),
    ],
    targets: [
        .target(
            name: "CrazyEightsModel"
        ),
        .testTarget(
            name: "CrazyEightsModelTests",
            dependencies: ["CrazyEightsModel"]
        ),
    ]
)
