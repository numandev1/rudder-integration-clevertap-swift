// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RudderCleverTap",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "RudderCleverTap",
            targets: ["RudderCleverTap"]),
    ],
    dependencies: [
        .package(url: "https://github.com/rudderlabs/rudder-sdk-ios.git", from: "2.4.3"),
        .package(url: "https://github.com/CleverTap/clevertap-ios-sdk.git", from: "6.2.1"),
    ],
    targets: [
        .target(
            name: "RudderCleverTap",
            dependencies: [
                .product(name: "Rudder", package: "rudder-sdk-ios"),
                .product(name: "CleverTapSDK", package: "clevertap-ios-sdk")
            ],
            path: "Sources"
        ),
    ]
)
