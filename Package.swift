// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UtilityKit",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v11),
        .iOS(.v14)
    ],
    products: [
        .library(name: "UtilityKit", targets: ["UtilityKit"]),
        .library(name: "TestUtility", targets: ["TestUtility"])
    ],
    dependencies: [],
    targets: [
        .target(name: "TestUtility", dependencies: []),
        .target(name: "UtilityKit", dependencies: []),
        .testTarget(name: "UtilityKitTests", dependencies: ["TestUtility", "UtilityKit"]),
    ]
)
