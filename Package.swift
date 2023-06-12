// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "LoadButton",
    products: [
        .library(
            name: "LoadButton",
            targets: ["LoadButton"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "LoadButton",
            dependencies: []),
        .testTarget(
            name: "LoadButtonTests",
            dependencies: ["LoadButton"]),
    ]
)
