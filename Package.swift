// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "abjc-api",
    platforms: [
        .iOS(.v14),
        .tvOS(.v14)
//        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "abjc-api",
            targets: ["abjc-api"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "abjc-api",
            dependencies: []),
        .testTarget(
            name: "abjc-apiTests",
            dependencies: ["abjc-api"]),
    ]
)
