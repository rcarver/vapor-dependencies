// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "vapor-dependencies",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "VaporDependencies", targets: ["VaporDependencies"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-dependencies.git", from: "1.0.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.8.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.83.1"),
    ],
    targets: [
        .target(
            name: "VaporDependencies",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "Vapor", package: "vapor"),
            ]
        ),
        .testTarget(
            name: "VaporDependenciesTests",
            dependencies: ["VaporDependencies"]
        ),
    ]
)
